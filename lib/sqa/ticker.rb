# sqa/lib/sqa/ticker.rb
#
# Stock ticker symbol validation and lookup using the dumbstockapi.com service.
# The ticker universe is downloaded once and kept in the market store's
# `tickers` table, replacing the old scan for `dumbstockapi-*.csv` files in the
# data directory.
#
# @example Validating a ticker
#   SQA::Ticker.valid?('AAPL')  # => true
#   SQA::Ticker.valid?('FAKE')  # => false
#
# @example Looking up ticker info
#   info = SQA::Ticker.lookup('AAPL')
#   info[:name]      # => "Apple Inc"
#   info[:exchange]  # => "NASDAQ"
#
class SQA::Ticker
  # @return [String] Prefix of the legacy downloaded CSV filenames
  FILENAME_PREFIX = "dumbstockapi".freeze

  # @return [Faraday::Connection] Connection to dumbstockapi.com
  CONNECTION      = Faraday.new(url: "https://dumbstockapi.com")

  # How many times a single process will attempt the download before giving up
  # and answering lookups as "unknown".
  DOWNLOAD_ATTEMPTS = 3

  class << self
    # @return [SQA::Store::Market] The store holding the ticker universe
    def store = @store ||= SQA::Store.market

    # Overrides the backing store. Chiefly for tests.
    #
    # @param value [SQA::Store::Market, nil]
    attr_writer :store

    # Downloads the ticker universe and replaces the stored snapshot.
    #
    # @param country [String] Country code for ticker list (default: "US")
    # @return [Integer] HTTP status code from the download request
    #
    # @example
    #   SQA::Ticker.download("US")  # => 200
    #
    def download(country = "US")
      response = CONNECTION.get("/stock?format=csv&countries=#{country.upcase}").to_hash
      return response[:status] unless response[:status] == 200

      rows = CSV.parse(response[:body], headers: true).map do |row|
        row.to_h.merge("country" => country.upcase)
      end
      store.replace_tickers(rows)

      response[:status]
    end

    # Ensures the universe is present, downloading it if the store is empty.
    #
    # The download is attempted at most once per process: a machine with no
    # network should answer lookups as "unknown" quickly rather than retrying
    # on every single validation.
    #
    # @return [Integer] Number of symbols available
    def load
      return store.ticker_count if store.ticker_count.positive? || @download_attempted

      @download_attempted = true
      attempt_download

      if store.ticker_count.zero? && $VERBOSE
        warn "Warning: No ticker validation data available. Proceeding without validation."
      end

      store.ticker_count
    end

    # Loads ticker data from a CSV file into the store.
    #
    # @param csv_path [Pathname, String] Path to a dumbstockapi-format CSV
    # @return [Integer] Number of symbols written
    def load_from_csv(csv_path)
      store.replace_tickers(CSV.read(csv_path.to_s, headers: true).map(&:to_h))
    end

    # The whole ticker universe as a Hash, for backward compatibility.
    #
    # Materializes every symbol; {#lookup} and {#valid?} query the store
    # directly and should be preferred.
    #
    # @return [Hash{String => Hash}] Symbol to `{ name:, exchange: }`
    def data
      load

      store.tickers.to_h { |row| [row["symbol"], { name: row["name"], exchange: row["exchange"] }] }
    end

    # Looks up information for a specific ticker symbol.
    #
    # @param ticker [String, nil] Ticker symbol to look up
    # @return [Hash, nil] Hash with :name and :exchange keys, or nil if not found
    #
    # @example
    #   SQA::Ticker.lookup('AAPL')  # => { name: "Apple Inc", exchange: "NASDAQ" }
    #   SQA::Ticker.lookup('FAKE')  # => nil
    #
    def lookup(ticker)
      return nil if blank?(ticker)

      load
      row = store.ticker(ticker)
      return nil unless row

      { name: row["name"], exchange: row["exchange"] }
    end

    # Checks if a ticker symbol is valid (exists in the universe).
    #
    # @param ticker [String, nil] Ticker symbol to validate
    # @return [Boolean] true if ticker exists, false otherwise
    #
    # @example
    #   SQA::Ticker.valid?('AAPL')  # => true
    #   SQA::Ticker.valid?(nil)     # => false
    #
    def valid?(ticker)
      return false if blank?(ticker)

      load
      store.valid_ticker?(ticker)
    end

    # Clears the memoized store handle and re-arms the download attempt.
    # Useful for testing to force a fresh load.
    #
    # @return [nil]
    def reset!
      @store = nil
      @download_attempted = false
      nil
    end

    private

    def blank?(ticker) = ticker.nil? || ticker.to_s.empty?

    def attempt_download
      DOWNLOAD_ATTEMPTS.times do
        return if download == 200
      rescue StandardError => e
        warn "Warning: Could not download ticker list: #{e.message}" if $VERBOSE
      end
    end
  end
end
