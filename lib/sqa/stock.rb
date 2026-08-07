# lib/sqa/stock.rb

# Represents a stock with price history, metadata, and technical analysis capabilities.
# This is the primary domain object for interacting with stock data.
#
# @example Basic usage
#   stock = SQA::Stock.new(ticker: 'AAPL')
#   prices = stock.df["adj_close_price"].to_a
#   puts stock.to_s
#
# @example With different data source
#   stock = SQA::Stock.new(ticker: 'MSFT', source: :yahoo_finance)
#
class SQA::Stock
  extend Forwardable

  # Fetch source tried when the requested :source's fresh (uncached) fetch
  # fails and it isn't already this source. Alpha Vantage's free tier is
  # 25 requests/day (and now caps free-tier history at ~100 trading days),
  # so :fmp (~250 requests/day, up to ~5 years of history) is the default,
  # with Yahoo Finance's unofficial API (no key, no official quota, but
  # liable to its own IP-based rate limiting) as a second attempt before
  # giving up.
  FALLBACK_SOURCE = :yahoo_finance

  # Default Alpha Vantage API URL
  # @return [String] The base URL for Alpha Vantage API
  ALPHA_VANTAGE_URL = "https://www.alphavantage.co".freeze

  # @deprecated Use {.connection} method instead. Will be removed in v1.0.0
  # @return [Faraday::Connection] Legacy constant for backward compatibility
  CONNECTION = Faraday.new(url: ALPHA_VANTAGE_URL)

  class << self
    # Returns the current Faraday connection for API requests.
    # Allows injection of custom connections for testing or different configurations.
    #
    # @return [Faraday::Connection] The current connection instance
    def connection
      @connection ||= default_connection
    end

    # Sets a custom Faraday connection.
    # Useful for testing with mocks/stubs or configuring different API endpoints.
    #
    # @param conn [Faraday::Connection] Custom Faraday connection to use
    # @return [Faraday::Connection] The connection that was set
    def connection=(conn)
      @connection = conn
    end

    # Creates the default Faraday connection to Alpha Vantage.
    #
    # @return [Faraday::Connection] A new connection to Alpha Vantage API
    def default_connection
      Faraday.new(url: ALPHA_VANTAGE_URL)
    end

    # Resets the connection to default.
    # Useful for testing cleanup to ensure fresh state between tests.
    #
    # @return [nil]
    def reset_connection!
      @connection = nil
    end
  end

  # @!attribute [rw] data
  #   @return [SQA::DataFrame::Data] Stock metadata (ticker, name, exchange, etc.)
  # @!attribute [rw] df
  #   @return [SQA::DataFrame] Price and volume data as a DataFrame
  # @!attribute [rw] klass
  #   @return [Class] The data source class (e.g., SQA::DataFrame::AlphaVantage)
  # @!attribute [rw] transformers
  #   @return [Hash] Column transformers for data normalization
  # @!attribute [rw] strategy
  #   @return [SQA::Strategy, nil] Optional trading strategy attached to this stock
  attr_accessor :data, :df, :klass, :transformers, :strategy

  # Creates a new Stock instance and loads or fetches its data.
  #
  # @param ticker [String] The stock ticker symbol (e.g., 'AAPL', 'MSFT')
  # @param source [Symbol] The data source to use (:fmp, :yahoo_finance, or
  #   :alpha_vantage; :stooq also exists but stooq.com now requires solving
  #   a JavaScript proof-of-work challenge, so it no longer works from a
  #   plain HTTP client)
  # @raise [SQA::DataFetchError] If data cannot be fetched (from :source or
  #   the FALLBACK_SOURCE) and no cached data exists
  #
  # @example
  #   stock = SQA::Stock.new(ticker: 'AAPL')
  #   stock = SQA::Stock.new(ticker: 'GOOG', source: :yahoo_finance)
  #
  # @param ticker [String] The stock ticker symbol
  # @param source [Symbol] The data source to use
  # @param store [SQA::Store::Market, nil] Persistence layer; defaults to the
  #   configured `sqa.db`. Injectable so a Stock can be tested against a
  #   throwaway database.
  def initialize(ticker:, source: :fmp, store: nil)
    @ticker = ticker.downcase
    @source = source
    @store  = store

    # Validate the ticker only when nothing is cached and the result would
    # actually be reported. $VERBOSE is tested first because SQA::Ticker.valid?
    # can trigger a download of the ticker universe, and there is no reason to
    # pay for that to build a warning nobody will see.
    if $VERBOSE && !cached? && !SQA::Ticker.valid?(ticker)
      warn "Warning: Ticker #{ticker} could not be validated. Proceeding anyway."
    end

    @klass = "SQA::DataFrame::#{@source.to_s.camelize}".constantize
    @transformers = "SQA::DataFrame::#{@source.to_s.camelize}::TRANSFORMERS".constantize

    load_or_create_data
    update_dataframe
  end

  # The market store backing this stock.
  #
  # @return [SQA::Store::Market]
  def store = @store ||= SQA::Store.market

  # Whether both metadata and prices are already held for this ticker.
  #
  # @return [Boolean]
  def cached? = store.stock?(@ticker) && store.price_count(@ticker).positive?

  # Loads existing metadata from the store, or creates a minimal structure and
  # attempts to fetch an overview from the API.
  #
  # @return [void]
  def load_or_create_data
    record = store.stock(@ticker)

    if record
      @data = SQA::DataFrame::Data.new(record)
    else
      # Create minimal data structure
      create_data

      # Try to fetch overview data, but don't fail if we can't
      # This is optional metadata - we can work with just price data
      update

      # Save whatever data we have (even if overview fetch failed)
      save_data
    end
  end

  # Creates a new minimal data structure for the stock.
  #
  # @return [SQA::DataFrame::Data] The newly created data object
  def create_data
    @data = SQA::DataFrame::Data.new(ticker: @ticker, source: @source, indicators: {})
  end

  # Updates the stock's overview data from the API.
  # Silently handles errors since overview data is optional.
  #
  # @return [void]
  #
  # @example Update stock metadata from API
  #   stock = SQA::Stock.new(ticker: 'AAPL')
  #   stock.update  # Fetches latest company overview data
  #   stock.data.overview['market_capitalization']  # => 2500000000000
  #   stock.data.overview['pe_ratio']  # => 28.5
  #
  # @example Update is safe if API fails
  #   stock.update  # No error raised if API is unavailable
  #   # Warning logged but stock remains usable with cached data
  #
  def update
    merge_overview
  rescue StandardError => e
    # Log warning but don't fail - overview data is optional
    # Common causes: rate limits, network issues, API errors
    warn "Warning: Could not fetch overview data for #{@ticker} (#{e.class}: #{e.message}). Continuing without it."
  end

  # Enriches the stock's overview with company fundamentals from Financial
  # Modeling Prep (FMP): executives and dividend history that Alpha Vantage's
  # OVERVIEW doesn't provide, plus name / sector / industry / P/E / market cap.
  #
  # FMP values are merged into (and take precedence in) the existing overview
  # Hash, so this composes with whatever Alpha Vantage already populated.
  # Requires FMP_API_KEY in the environment.
  #
  # @param include_executives [Boolean] fetch the executives list (1 API call)
  # @param include_dividends [Boolean] fetch dividend history (1 API call)
  # @return [Hash] The merged overview
  #
  # @example
  #   stock = SQA::Stock.new(ticker: 'AAPL')
  #   stock.merge_fmp_overview
  #   stock.overview['ceo']          # => "Mr. Timothy D. Cook"
  #   stock.overview['sector']       # => "Technology"
  #   stock.overview['executives']   # => [{ "name" => ..., "title" => ... }, ...]
  #   stock.overview['dividends']    # => [{ "date" => ..., "dividend" => ... }, ...]
  #
  def merge_fmp_overview(include_executives: true, include_dividends: true)
    fmp = SQA::FMP.overview(@ticker,
                            include_executives: include_executives,
                            include_dividends:  include_dividends)
    @data.overview = (@data.overview || {}).merge(fmp)
  end

  # Persists the stock's metadata to the market store.
  #
  # @return [String] The ticker written
  def save_data
    store.save_stock(
      ticker:     @data.ticker || @ticker,
      source:     @data.source || @source,
      name:       @data.name,
      exchange:   @data.exchange,
      overview:   @data.overview   || {},
      indicators: @data.indicators || {}
    )
  end

  # @!method ticker
  #   @return [String] The stock's ticker symbol
  # @!method name
  #   @return [String, nil] The company name
  # @!method exchange
  #   @return [String, nil] The exchange where the stock trades
  # @!method source
  #   @return [Symbol] The data source (:alpha_vantage or :yahoo_finance)
  # @!method indicators
  #   @return [Hash] Cached indicator values
  # @!method indicators=(value)
  #   @param value [Hash] New indicator values
  # @!method overview
  #   @return [Hash, nil] Company overview data from API
  def_delegators :@data, :ticker, :name, :exchange, :source, :indicators, :indicators=, :overview

  # Updates the DataFrame with price data.
  # Loads from cache if available, otherwise fetches from API.
  # Applies migrations for old data formats and updates with recent data.
  #
  # @return [void]
  # @raise [SQA::DataFetchError] If data cannot be fetched and no cache exists
  # Loads price data into {#df} from the store, adopting a legacy CSV or
  # fetching from the API if the store holds nothing yet.
  #
  # The column-renaming and adj_close_price migrations that this method used to
  # perform on every load are gone: the `prices` table names its columns, so
  # there is no longer a format to sniff.
  #
  # @return [void]
  # @raise [SQA::DataFetchError] If data cannot be fetched and nothing is cached
  def update_dataframe
    rows = store.prices(@ticker)
    rows = adopt_legacy_csv if rows.empty?

    if rows.empty?
      @df = fetch_and_store_prices
      return
    end

    @df = SQA::DataFrame.from_aofh(rows)

    update_dataframe_with_recent_data
  end

  # Adopts a pre-SQLite `<ticker>.csv` from data_dir into the store.
  #
  # This is what makes upgrading free: the first run after the store landed
  # finds the old cache and imports it instead of re-fetching history the user
  # already had. The source file is read, never modified or removed.
  #
  # @return [Array<Hash>] The rows now held, or [] if there was no legacy file
  def adopt_legacy_csv
    legacy = SQA.data_dir + "#{@ticker}.csv"
    return [] unless legacy.exist?

    rows = SQA::Store::Importer.price_rows_from_csv(legacy)
    return [] if rows.empty?

    persist_prices(rows)
    warn "Adopted legacy #{legacy.basename} into the market store" if $VERBOSE

    store.prices(@ticker)
  end

  # Fetches full history and writes it to the store.
  #
  # @return [SQA::DataFrame]
  # @raise [SQA::DataFetchError]
  def fetch_and_store_prices
    df = fetch_fresh_dataframe
    persist_prices(df.to_aofh)
    df
  rescue StandardError => e
    raise SQA::DataFetchError.new(
      "Unable to fetch data for #{@ticker}. Please ensure an API key is set, or import an existing " \
      "cache with SQA::Store::Importer. Error: #{e.message}",
      original: e
    )
  end

  # Fetches the full price history from @klass (the requested :source),
  # falling back to FALLBACK_SOURCE if that fails and it isn't already the
  # source in use. One source's failure (rate limit, missing key, network)
  # doesn't necessarily mean the other's will too.
  #
  # @return [SQA::DataFrame]
  def fetch_fresh_dataframe
    @klass.recent(@ticker, full: true)
  rescue StandardError => e
    fallback_klass = "SQA::DataFrame::#{FALLBACK_SOURCE.to_s.camelize}".constantize
    raise if @klass == fallback_klass

    warn "Warning: Could not fetch #{@ticker} from #{@source} (#{e.class}: #{e.message}). " \
         "Trying #{FALLBACK_SOURCE} instead."
    fallback_klass.recent(@ticker, full: true)
  end

  # Fetches recent data from API and appends to existing DataFrame.
  # Only called if should_update? returns true.
  #
  # @return [void]
  def update_dataframe_with_recent_data
    return unless should_update?

    begin
      # Rows are ascending (oldest first, TA-Lib compatible), so .last is the most recent date
      from_date = Date.parse(@df["timestamp"].to_a.last)
      df_2 = @klass.recent(@ticker, from_date: from_date)

      if df_2 && df_2.size.positive?
        # The (ticker, timestamp) primary key absorbs any overlap with what we
        # already hold, so no in-memory deduplication is needed first.
        store.save_prices(@ticker, df_2.to_aofh)
        @df = SQA::DataFrame.from_aofh(store.prices(@ticker))
      end
    rescue StandardError => e
      # Log warning but don't fail - we have cached data
      # Common causes: rate limits, network issues, API errors
      warn "Warning: Could not update #{@ticker} from API (#{e.class}: #{e.message}). Using cached data."
    end
  end

  # Writes rows for this ticker, creating the parent stocks row if the price
  # data arrived before any metadata did.
  #
  # @param rows [Array<Hash>]
  # @return [Integer] Rows written
  def persist_prices(rows)
    store.save_stock(ticker: @ticker, source: @source) unless store.stock?(@ticker)
    store.save_prices(@ticker, rows)
  end

  # @deprecated Use {#update_dataframe} instead. Will be removed in v1.0.0
  # @return [void]
  def update_the_dataframe
    warn "[SQA DEPRECATION] update_the_dataframe is deprecated; use update_dataframe instead" if $VERBOSE
    update_dataframe
  end

  # Determines whether the DataFrame should be updated from the API.
  # Returns false if lazy_update is enabled, API key is missing,
  # or data is already current.
  #
  # @return [Boolean] true if update should proceed, false otherwise
  def should_update?
    # Don't update if we're in lazy update mode
    return false if SQA.config.lazy_update

    # Don't update if we don't have an API key (only relevant for sources
    # that require one -- Yahoo Finance doesn't)
    if %i[alpha_vantage fmp].include?(@source)
      begin
        @source == :alpha_vantage ? SQA.av_api_key : SQA.fmp_api_key
      rescue SQA::ConfigurationError
        return false
      end
    end

    # Don't update if CSV data is already current (last timestamp is today or later)
    # This prevents unnecessary API calls when we already have today's data
    if @df && @df.size.positive?
      begin
        last_timestamp = Date.parse(@df["timestamp"].to_a.last)
        return false if last_timestamp >= Date.today
      rescue ArgumentError => e
        # If we can't parse the date, assume we need to update
        warn "Warning: Could not parse last timestamp for #{@ticker} (#{e.message}). Will attempt update." if $VERBOSE
      end
    end

    true
  end

  # Returns a human-readable string representation of the stock.
  #
  # @return [String] Summary including ticker, data points count, and date range
  #
  # @example
  #   stock.to_s  # => "aapl with 252 data points from 2023-01-03 to 2023-12-29"
  def to_s
    "#{ticker} with #{@df.size} data points from #{@df["timestamp"].to_a.first} to #{@df["timestamp"].to_a.last}"
  end
  # NOTE: CSV data is stored in ascending chronological order (oldest to newest)
  # This ensures compatibility with TA-Lib indicators which expect arrays in this order
  alias inspect to_s

  # Fetches and merges company overview data from Alpha Vantage API.
  # Converts API response keys to snake_case and appropriate data types.
  #
  # @return [Hash] The merged overview data
  # @raise [ApiError] If the API returns an error response
  def merge_overview
    temp = JSON.parse(
      self.class.connection.get("/query?function=OVERVIEW&symbol=#{ticker.upcase}&apikey=#{SQA.av.key}")
      .to_hash[:body]
    )

    if temp.key?("Information")
      ApiError.raise(temp["Information"])
    end

    temp_2 = {}
    string_values = %w[address asset_type cik country currency description dividend_date ex_dividend_date exchange fiscal_year_end industry
                       latest_quarter name sector symbol]

    temp.each_key do |k|
      new_k = k.underscore
      temp_2[new_k] = string_values.include?(new_k) ? temp[k] : temp[k].to_f
    end

    @data.overview = temp_2
  end

  #############################################
  ## Class Methods

  class << self
    # Fetches top gainers, losers, and most actively traded stocks from Alpha Vantage.
    # Results are cached after the first call.
    #
    # @return [Hashie::Mash] Object with top_gainers, top_losers, and most_actively_traded arrays
    #
    # @example
    #   top = SQA::Stock.top
    #   top.top_gainers.each { |stock| puts "#{stock.ticker}: +#{stock.change_percentage}%" }
    #   top.top_losers.first.ticker  # => "XYZ"
    #
    def top
      return @top if @top

      a_hash = JSON.parse(connection.get("/query?function=TOP_GAINERS_LOSERS&apikey=#{SQA.av.key}").to_hash[:body])

      mash = Hashie::Mash.new(a_hash)

      keys = mash.top_gainers.first.keys

      %w[top_gainers top_losers most_actively_traded].each do |collection|
        mash.send(collection).each do |e|
          keys.each do |k|
            case k
            when 'ticker'
              # Leave it as a String
            when 'volume'
              e[k] = e[k].to_i
            else
              e[k] = e[k].to_f
            end
          end
        end
      end

      @top = mash
    end

    # Resets the cached top gainers/losers data.
    # Useful for testing or forcing a refresh.
    #
    # @return [nil]
    def reset_top!
      @top = nil
    end
  end
end
