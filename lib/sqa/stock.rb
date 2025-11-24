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
  # @param source [Symbol] The data source to use (:alpha_vantage or :yahoo_finance)
  # @raise [SQA::DataFetchError] If data cannot be fetched and no cached data exists
  #
  # @example
  #   stock = SQA::Stock.new(ticker: 'AAPL')
  #   stock = SQA::Stock.new(ticker: 'GOOG', source: :yahoo_finance)
  #
  def initialize(ticker:, source: :alpha_vantage)
    @ticker = ticker.downcase
    @source = source

    @data_path = SQA.data_dir + "#{@ticker}.json"
    @df_path = SQA.data_dir + "#{@ticker}.csv"

    # Validate ticker if validation data is available and cached data doesn't exist
    unless @data_path.exist? && @df_path.exist?
      unless SQA::Ticker.valid?(ticker)
        warn "Warning: Ticker #{ticker} could not be validated. Proceeding anyway." if $VERBOSE
      end
    end

    @klass = "SQA::DataFrame::#{@source.to_s.camelize}".constantize
    @transformers = "SQA::DataFrame::#{@source.to_s.camelize}::TRANSFORMERS".constantize

    load_or_create_data
    update_dataframe
  end

  # Loads existing data from cache or creates new data structure.
  # If cached data exists, loads from JSON file. Otherwise creates
  # minimal structure and attempts to fetch overview from API.
  #
  # @return [void]
  def load_or_create_data
    if @data_path.exist?
      @data = SQA::DataFrame::Data.new(JSON.parse(@data_path.read))
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
  def update
    begin
      merge_overview
    rescue StandardError => e
      # Log warning but don't fail - overview data is optional
      # Common causes: rate limits, network issues, API errors
      warn "Warning: Could not fetch overview data for #{@ticker} (#{e.class}: #{e.message}). Continuing without it."
    end
  end

  # Persists the stock's metadata to a JSON file.
  #
  # @return [Integer] Number of bytes written
  def save_data
    @data_path.write(@data.to_json)
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
  def update_dataframe
    if @df_path.exist?
      # Load cached CSV - transformers already applied when data was first fetched
      # Don't reapply them as columns are already in correct format
      @df = SQA::DataFrame.load(source: @df_path)

      migrated = false

      # Migration 1: Rename old column names to new convention
      # Old files may have: open, high, low, close
      # New files should have: open_price, high_price, low_price, close_price
      if @df.columns.include?("open") && !@df.columns.include?("open_price")
        old_to_new_mapping = {
          "open"   => "open_price",
          "high"   => "high_price",
          "low"    => "low_price",
          "close"  => "close_price"
        }
        @df.rename_columns!(old_to_new_mapping)
        migrated = true
      end

      # Migration 2: Add adj_close_price column if missing (for old cached files)
      # This ensures compatibility when appending new data that includes this column
      unless @df.columns.include?("adj_close_price")
        @df.data = @df.data.with_column(
          @df.data["close_price"].alias("adj_close_price")
        )
        migrated = true
      end

      # Save migrated DataFrame to avoid repeating migration
      @df.to_csv(@df_path) if migrated
    else
      # Fetch fresh data from source (applies transformers and mapping)
      begin
        @df = @klass.recent(@ticker, full: true)
        @df.to_csv(@df_path)
        return
      rescue StandardError => e
        # If we can't fetch data, raise a more helpful error
        raise SQA::DataFetchError.new(
          "Unable to fetch data for #{@ticker}. Please ensure API key is set or provide cached CSV file at #{@df_path}. Error: #{e.message}",
          original: e
        )
      end
    end

    update_dataframe_with_recent_data
  end

  # Fetches recent data from API and appends to existing DataFrame.
  # Only called if should_update? returns true.
  #
  # @return [void]
  def update_dataframe_with_recent_data
    return unless should_update?

    begin
      # CSV is sorted ascending (oldest first, TA-Lib compatible), so .last gets the most recent date
      from_date = Date.parse(@df["timestamp"].to_a.last)
      df2 = @klass.recent(@ticker, from_date: from_date)

      if df2 && (df2.size > 0)
        # Use concat_and_deduplicate! to prevent duplicate timestamps and maintain ascending sort
        @df.concat_and_deduplicate!(df2)
        @df.to_csv(@df_path)
      end
    rescue StandardError => e
      # Log warning but don't fail - we have cached data
      # Common causes: rate limits, network issues, API errors
      warn "Warning: Could not update #{@ticker} from API (#{e.class}: #{e.message}). Using cached data."
    end
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

    # Don't update if we don't have an API key (only relevant for Alpha Vantage)
    if @source == :alpha_vantage
      begin
        SQA.av_api_key
      rescue SQA::ConfigurationError
        return false
      end
    end

    # Don't update if CSV data is already current (last timestamp is today or later)
    # This prevents unnecessary API calls when we already have today's data
    if @df && @df.size > 0
      begin
        last_timestamp = Date.parse(@df["timestamp"].to_a.last)
        return false if last_timestamp >= Date.today
      rescue ArgumentError, Date::Error => e
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
  # Note: CSV data is stored in ascending chronological order (oldest to newest)
  # This ensures compatibility with TA-Lib indicators which expect arrays in this order
  alias_method :inspect, :to_s

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

    temp2 = {}
    string_values = %w[address asset_type cik country currency description dividend_date ex_dividend_date exchange fiscal_year_end industry latest_quarter name sector symbol]

    temp.keys.each do |k|
      new_k = k.underscore
      temp2[new_k] = string_values.include?(new_k) ? temp[k] : temp[k].to_f
    end

    @data.overview = temp2
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
