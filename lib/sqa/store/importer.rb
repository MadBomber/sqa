# lib/sqa/store/importer.rb
# frozen_string_literal: true

require 'csv'
require 'json'
require 'fileutils'
require_relative 'market'
require_relative 'portfolio'

module SQA
  module Store
    # One-time migration of a legacy `data_dir` into the SQLite stores.
    #
    # The legacy layout was a single flat directory keyed only by ticker, which
    # gave `<ticker>.json` two incompatible meanings: stock metadata written by
    # {SQA::Stock}, and raw `{"summary", "chart"}` caches written by the Yahoo
    # example scripts. This importer tells them apart by *schema* rather than
    # by filename, moves the impostors aside, and leaves every original file
    # where it found it.
    #
    # Nothing is deleted. Price CSVs and metadata JSON are copied into the
    # stores; the source files remain readable until you choose to remove them.
    #
    # @example
    #   report = SQA::Store::Importer.new(data_dir: "~/sqa_data").run
    #   puts report
    #
    class Importer
      # Files whose basename starts with this are the ticker universe, not a
      # per-ticker price file. Mirrors SQA::Ticker::FILENAME_PREFIX.
      TICKER_UNIVERSE_PREFIX = 'dumbstockapi'

      # Where a `{"summary", "chart"}` file gets moved to, relative to data_dir.
      QUARANTINE_DIRNAME = 'quarantined_yahoo_cache'

      # What the run did. Every collection holds ticker symbols or filenames,
      # so a caller can act on the result rather than only print it.
      Report = Data.define(:prices, :metadata, :quarantined, :tickers, :portfolios, :skipped) do
        # @return [Integer] Total price rows written across all tickers
        def price_rows = prices.values.sum

        def to_s
          <<~REPORT
            Imported into the SQA stores:
              prices        #{prices.size} ticker(s), #{price_rows} row(s)
              metadata      #{metadata.size} stock(s)
              ticker list   #{tickers} symbol(s)
              portfolios    #{portfolios.size} #{portfolios.join(', ')}
              quarantined   #{quarantined.size} file(s)#{" -> #{QUARANTINE_DIRNAME}/" unless quarantined.empty?}
              skipped       #{skipped.size} file(s)#{": #{skipped.join(', ')}" unless skipped.empty?}
          REPORT
        end
      end

      # @return [Pathname] The legacy data directory being read
      attr_reader :data_dir

      # @param data_dir [String, Pathname] Legacy directory to import from
      # @param market [SQA::Store::Market] Destination for stocks/prices/tickers
      # @param portfolio [SQA::Store::Portfolio] Destination for portfolios
      # @param quarantine_dir [String, Pathname, nil] Where impostor JSON goes;
      #   defaults to `<data_dir>/#{QUARANTINE_DIRNAME}`
      def initialize(data_dir:, market: nil, portfolio: nil, quarantine_dir: nil)
        @data_dir       = Pathname.new(data_dir.to_s).expand_path
        @market         = market
        @portfolio      = portfolio
        @quarantine_dir = Pathname.new((quarantine_dir || (@data_dir + QUARANTINE_DIRNAME)).to_s)
      end

      # @return [SQA::Store::Market]
      def market = @market ||= Store.market

      # @return [SQA::Store::Portfolio]
      def portfolio = @portfolio ||= Store.portfolio

      # Runs the import.
      #
      # @param dry_run [Boolean] Report what would happen without writing
      # @return [Report]
      def run(dry_run: false)
        @dry_run     = dry_run
        @prices      = {}
        @metadata    = []
        @quarantined = []
        @skipped     = []
        @portfolios  = []
        @tickers     = 0

        import_metadata
        import_prices
        import_ticker_universe
        import_legacy_portfolio

        Report.new(prices: @prices, metadata: @metadata, quarantined: @quarantined,
                   tickers: @tickers, portfolios: @portfolios, skipped: @skipped)
      end

      class << self
        # Classifies a parsed JSON document without trusting its filename.
        #
        # @param document [Object] Parsed JSON
        # @return [Symbol] :metadata, :yahoo_cache, or :unknown
        def classify(document)
          return :unknown unless document.is_a?(Hash)
          return :metadata    if document.key?('ticker')
          return :yahoo_cache if document.key?('summary') || document.key?('chart')

          :unknown
        end

        # Reads a legacy price CSV into store-shaped rows, tolerating both the
        # current column names and the pre-migration ones (`open`, `high`,
        # `low`, `close`, `date`).
        #
        # @param file [String, Pathname]
        # @return [Array<Hash>] Empty if the file is unreadable or has no rows
        def price_rows_from_csv(file)
          CSV.read(file.to_s, headers: true).filter_map do |row|
            hash = row.to_h
            next if hash.values.all? { |value| value.nil? || value.to_s.strip.empty? }

            stamp = hash['timestamp'] || hash['date']
            next if stamp.to_s.strip.empty?

            price_row(hash, stamp)
          end
        rescue CSV::MalformedCSVError, Errno::ENOENT
          []
        end

        private

        def price_row(hash, stamp)
          close = numeric(hash['close_price'] || hash['close'])

          {
            'timestamp'       => stamp,
            'open_price'      => numeric(hash['open_price'] || hash['open']),
            'high_price'      => numeric(hash['high_price'] || hash['high']),
            'low_price'       => numeric(hash['low_price']  || hash['low']),
            'close_price'     => close,
            'adj_close_price' => numeric(hash['adj_close_price'] || hash['adjusted_close']) || close,
            'volume'          => hash['volume'].to_s.strip.empty? ? nil : hash['volume'].to_i
          }
        end

        def numeric(value) = value.to_s.strip.empty? ? nil : value.to_f
      end

      private

      def import_metadata
        @data_dir.glob('*.json').sort.each do |file|
          document = parse_json(file) or next

          case self.class.classify(document)
          when :metadata    then save_metadata(file, document)
          when :yahoo_cache then quarantine(file)
          else                   @skipped << file.basename.to_s
          end
        end
      end

      def save_metadata(file, document)
        ticker = document['ticker'].to_s
        return @skipped << file.basename.to_s if ticker.empty?

        unless @dry_run
          market.save_stock(
            ticker:,
            source:     document['source'] || :fmp,
            name:       document['name'],
            exchange:   document['exchange'],
            overview:   document['overview']   || {},
            indicators: document['indicators'] || {}
          )
        end

        @metadata << ticker
      end

      # Moved, never deleted -- these files are someone's cache, and the point
      # of the move is only to stop them colliding with a ticker's metadata.
      def quarantine(file)
        unless @dry_run
          @quarantine_dir.mkpath
          FileUtils.mv(file.to_s, (@quarantine_dir + file.basename).to_s)
        end

        @quarantined << file.basename.to_s
      end

      def import_prices
        @data_dir.glob('*.csv').sort.each do |file|
          next if file.basename.to_s.start_with?(TICKER_UNIVERSE_PREFIX)

          ticker = file.basename('.csv').to_s.downcase
          rows   = self.class.price_rows_from_csv(file)

          if rows.empty?
            @skipped << file.basename.to_s
            next
          end

          unless @dry_run
            # A price CSV can exist with no metadata sidecar, and prices are
            # foreign-keyed to stocks, so ensure the parent row exists first.
            market.save_stock(ticker:, source: :fmp) unless market.stock?(ticker)
            market.save_prices(ticker, rows)
          end

          @prices[ticker] = rows.size
        end
      end

      # The newest ticker-universe snapshot wins; older ones are only history.
      def import_ticker_universe
        files = @data_dir.children.select { |child| child.basename.to_s.start_with?(TICKER_UNIVERSE_PREFIX) }.sort
        return if files.empty?

        rows = CSV.read(files.last.to_s, headers: true).map(&:to_h)
        market.replace_tickers(rows) unless @dry_run

        @tickers = rows.size
      end

      # The legacy portfolio.csv carried positions only -- no cash, no
      # initial_cash, no commission (SQA::Portfolio#save_to_csv never wrote
      # them). Positions therefore arrive as `open` rows, which is exactly
      # what `open` is for: holdings with no recoverable trade history.
      def import_legacy_portfolio
        positions = @data_dir + SQA.config.portfolio_filename
        trades    = @data_dir + SQA.config.trades_filename
        return unless positions.exist? || trades.exist?

        name = 'Imported Portfolio'
        return @skipped << "#{name} (name already taken)" if !@dry_run && portfolio.portfolio(name)

        @portfolios << name
        return if @dry_run

        id = portfolio.create_portfolio(name:, kind: 'simulated')
        import_legacy_positions(id, positions) if positions.exist?
        import_legacy_trades(id, trades)       if trades.exist?
      end

      def import_legacy_positions(id, file)
        CSV.foreach(file.to_s, headers: true) do |row|
          shares = row['shares'].to_f
          cost   = row['avg_cost'].to_f
          next unless shares.positive? && cost.positive?

          portfolio.record_trade(portfolio_id: id, ticker: row['ticker'], action: 'open',
                                 shares:, price: cost, note: 'imported from portfolio.csv')
        end
      end

      def import_legacy_trades(id, file)
        CSV.foreach(file.to_s, headers: true) do |row|
          shares = row['shares'].to_f
          price  = row['price'].to_f
          next unless shares.positive? && price.positive?

          portfolio.record_trade(portfolio_id: id, ticker: row['ticker'], action: row['action'].to_s.downcase,
                                 shares:, price:, commission: row['commission'].to_f,
                                 traded_on: row['date'], note: 'imported from trades.csv')
        rescue SQA::BadParameterError => e
          # A legacy trades.csv has no guarantee of internal consistency -- it
          # was written without any constraint that a sale be covered.
          @skipped << "#{file.basename} #{row['ticker']} #{row['action']} (#{e.message})"
        end
      end

      def parse_json(file)
        JSON.parse(file.read)
      rescue JSON::ParserError
        @skipped << file.basename.to_s
        nil
      end
    end
  end
end
