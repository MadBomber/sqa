# lib/sqa/store/market.rb
# frozen_string_literal: true

require 'json'
require_relative 'base'

module SQA
  module Store
    # Persistent store for market data: stock metadata, daily price history,
    # and the ticker universe. Backed by `sqa.db`.
    #
    # Everything here is *derived* data — re-fetchable from an upstream API.
    # Deleting this file costs nothing but network calls, which is precisely
    # why portfolios live in a separate database ({SQA::Store::Portfolio}).
    #
    # @example
    #   store = SQA::Store::Market.new("~/sqa_data/sqa.db")
    #   store.save_stock(ticker: "aapl", source: :fmp)
    #   store.save_prices("aapl", rows)
    #   store.prices("aapl").first["date"]  # => "1999-11-01"
    #
    class Market < Base
      # Column names match SQA::DataFrame's convention exactly, so no rename
      # layer is needed between storage and the Polars frame.
      PRICE_COLUMNS = %w[
        timestamp open_price high_price low_price close_price adj_close_price volume
      ].freeze

      # Ordered, append-only DDL batches. See {Base#migrations}.
      #
      # @return [Array<String>]
      def migrations
        [<<~SQL]
          CREATE TABLE stocks (
            ticker      TEXT PRIMARY KEY,
            name        TEXT,
            exchange    TEXT,
            source      TEXT NOT NULL,
            overview    TEXT,
            indicators  TEXT,
            updated_at  TEXT NOT NULL
          );

          CREATE TABLE prices (
            ticker          TEXT NOT NULL REFERENCES stocks(ticker) ON DELETE CASCADE,
            timestamp       TEXT NOT NULL,
            open_price      REAL,
            high_price      REAL,
            low_price       REAL,
            close_price     REAL,
            adj_close_price REAL,
            volume          INTEGER,
            PRIMARY KEY (ticker, timestamp)
          ) WITHOUT ROWID;

          CREATE TABLE tickers (
            symbol     TEXT PRIMARY KEY,
            name       TEXT,
            exchange   TEXT,
            country    TEXT,
            is_etf     INTEGER,
            fetched_at TEXT NOT NULL
          );
        SQL
      end

      #############################################
      ## Stocks

      # Inserts or updates a stock's metadata.
      #
      # @param ticker [String] Canonical (lowercase) ticker symbol
      # @param source [Symbol, String] Data source the prices came from
      # @param name [String, nil] Company name
      # @param exchange [String, nil] Listing exchange
      # @param overview [Hash, nil] Company overview, stored as JSON
      # @param indicators [Hash, nil] Cached indicator config, stored as JSON
      # @return [String] The ticker written
      def save_stock(ticker:, source:, name: nil, exchange: nil, overview: {}, indicators: {})
        key = normalize(ticker)

        db.execute(<<~SQL, [key, name, exchange, source.to_s, JSON.generate(overview || {}), JSON.generate(indicators || {}), Base.now])
          INSERT INTO stocks (ticker, name, exchange, source, overview, indicators, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(ticker) DO UPDATE SET
            name       = COALESCE(excluded.name, stocks.name),
            exchange   = COALESCE(excluded.exchange, stocks.exchange),
            source     = excluded.source,
            overview   = excluded.overview,
            indicators = excluded.indicators,
            updated_at = excluded.updated_at
        SQL

        key
      end

      # Fetches a stock's metadata, decoding the JSON columns.
      #
      # @param ticker [String]
      # @return [Hash, nil] Metadata with symbolized :overview/:indicators, or nil
      def stock(ticker)
        row = db.get_first_row('SELECT * FROM stocks WHERE ticker = ?', [normalize(ticker)])
        return nil unless row

        row.merge(
          'overview'   => parse_json(row['overview']),
          'indicators' => parse_json(row['indicators'])
        )
      end

      # @return [Array<String>] Every ticker with a stocks row, alphabetically
      def stock_tickers = db.execute('SELECT ticker FROM stocks ORDER BY ticker').map { |r| r['ticker'] }

      # @param ticker [String]
      # @return [Boolean]
      def stock?(ticker) = !db.get_first_value('SELECT 1 FROM stocks WHERE ticker = ?', [normalize(ticker)]).nil?

      # Removes a stock and (via ON DELETE CASCADE) all of its prices.
      #
      # @param ticker [String]
      # @return [Integer] Rows deleted from stocks
      def delete_stock(ticker)
        db.execute('DELETE FROM stocks WHERE ticker = ?', [normalize(ticker)])
        db.changes
      end

      #############################################
      ## Prices

      # Inserts or updates daily price rows for a ticker.
      #
      # Existing (ticker, date) rows are overwritten rather than duplicated, so
      # re-importing overlapping history is idempotent — the deduplication that
      # SQA::Stock#concat_and_deduplicate! performs in memory becomes a
      # property of the primary key.
      #
      # @param ticker [String]
      # @param rows [Array<Hash>] Rows keyed by {PRICE_COLUMNS} names (String or Symbol)
      # @return [Integer] Number of rows written
      def save_prices(ticker, rows)
        key = normalize(ticker)
        return 0 if rows.nil? || rows.empty?

        statement = db.prepare(<<~SQL)
          INSERT INTO prices (ticker, timestamp, open_price, high_price, low_price,
                              close_price, adj_close_price, volume)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(ticker, timestamp) DO UPDATE SET
            open_price      = excluded.open_price,
            high_price      = excluded.high_price,
            low_price       = excluded.low_price,
            close_price     = excluded.close_price,
            adj_close_price = excluded.adj_close_price,
            volume          = excluded.volume
        SQL

        begin
          transaction do
            rows.each { |row| statement.execute(price_values(key, row)) }
          end
        ensure
          statement.close
        end

        rows.size
      end

      # Daily prices in ascending date order — the oldest-first ordering TA-Lib
      # requires. The composite primary key clusters rows this way already, so
      # no sort is performed at read time.
      #
      # @param ticker [String]
      # @param from [Date, String, nil] Inclusive lower bound
      # @param to [Date, String, nil] Inclusive upper bound
      # @return [Array<Hash>]
      def prices(ticker, from: nil, to: nil)
        sql    = +'SELECT timestamp, open_price, high_price, low_price, close_price, adj_close_price, volume FROM prices WHERE ticker = ?'
        values = [normalize(ticker)]

        if from
          sql << ' AND timestamp >= ?'
          values << Base.iso_date(from)
        end

        if to
          sql << ' AND timestamp <= ?'
          values << Base.iso_date(to)
        end

        db.execute("#{sql} ORDER BY timestamp ASC", values)
      end

      # @param ticker [String]
      # @return [Integer] Number of price rows held for the ticker
      def price_count(ticker) = db.get_first_value('SELECT COUNT(*) FROM prices WHERE ticker = ?', [normalize(ticker)]).to_i

      # The date range held for a ticker, without scanning the rows.
      #
      # @param ticker [String]
      # @return [Hash{Symbol => String, nil}] `{ first:, last:, count: }`
      def coverage(ticker)
        row = db.get_first_row(
          'SELECT MIN(timestamp) AS first, MAX(timestamp) AS last, COUNT(*) AS count FROM prices WHERE ticker = ?',
          [normalize(ticker)]
        )

        { first: row['first'], last: row['last'], count: row['count'].to_i }
      end

      # @param ticker [String]
      # @return [String, nil] Most recent date held, ISO-8601
      def last_price_date(ticker) = db.get_first_value('SELECT MAX(timestamp) FROM prices WHERE ticker = ?', [normalize(ticker)])

      #############################################
      ## Ticker universe

      # Replaces the ticker universe wholesale — it is a snapshot, not an
      # accumulation, so a symbol delisted upstream must disappear here too.
      #
      # @param rows [Array<Hash>] Keyed by symbol (or ticker), name, exchange,
      #   country, is_etf
      # @return [Integer] Number of symbols written
      def replace_tickers(rows)
        stamp = Base.now

        transaction do
          db.execute('DELETE FROM tickers')

          statement = db.prepare(
            'INSERT OR REPLACE INTO tickers (symbol, name, exchange, country, is_etf, fetched_at) VALUES (?, ?, ?, ?, ?, ?)'
          )
          begin
            rows.each { |row| statement.execute(ticker_values(row, stamp)) }
          ensure
            statement.close
          end
        end

        rows.size
      end

      # @param symbol [String]
      # @return [Hash, nil]
      def ticker(symbol) = db.get_first_row('SELECT * FROM tickers WHERE symbol = ?', [symbol.to_s.upcase])

      # The whole ticker universe. Prefer {#ticker} or {#valid_ticker?} for a
      # single lookup — those are indexed and do not materialize ~7,000 rows.
      #
      # @return [Array<Hash>]
      def tickers = db.execute('SELECT * FROM tickers ORDER BY symbol')

      # @param symbol [String]
      # @return [Boolean] Whether the symbol appears in the ticker universe
      def valid_ticker?(symbol) = !db.get_first_value('SELECT 1 FROM tickers WHERE symbol = ?', [symbol.to_s.upcase]).nil?

      # @return [Integer] Size of the ticker universe
      def ticker_count = db.get_first_value('SELECT COUNT(*) FROM tickers').to_i

      private

      # Tickers are stored lowercase to match SQA::Stock#initialize, which
      # downcases before building its file paths.
      def normalize(ticker) = ticker.to_s.strip.downcase

      def parse_json(value) = value.nil? || value.empty? ? {} : JSON.parse(value)

      # dumbstockapi spells the symbol column "ticker" and reports is_etf as
      # the string "null" when unknown, so both are normalized here.
      def ticker_values(row, stamp)
        etf = fetch_any(row, :is_etf)

        [
          fetch_any(row, :symbol, :ticker).to_s.upcase,
          fetch_any(row, :name),
          fetch_any(row, :exchange),
          fetch_any(row, :country),
          boolean_flag(etf),
          stamp
        ]
      end

      def boolean_flag(value)
        case value.to_s.downcase
        when 'true', '1'  then 1
        when 'false', '0' then 0
        end
      end

      def price_values(ticker, row)
        [
          ticker,
          Base.iso_date(fetch_any(row, :timestamp, :date)),
          fetch_any(row, :open_price, :open),
          fetch_any(row, :high_price, :high),
          fetch_any(row, :low_price, :low),
          fetch_any(row, :close_price, :close),
          fetch_any(row, :adj_close_price, :adjusted_close, :close_price, :close),
          fetch_any(row, :volume)
        ]
      end

      # Reads the first present key, accepting either String or Symbol forms so
      # callers can pass Polars rows, CSV rows, or plain hashes unchanged.
      def fetch_any(row, *keys)
        keys.each do |key|
          return row[key]      if row.key?(key)
          return row[key.to_s] if row.key?(key.to_s)
        end

        nil
      end
    end
  end
end
