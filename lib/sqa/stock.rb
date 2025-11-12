# lib/sqa/stock.rb

class SQA::Stock
  extend Forwardable

  CONNECTION = Faraday.new(url: "https://www.alphavantage.co")

  attr_accessor :data, :df, :klass, :transformers, :strategy

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
    update_the_dataframe
  end

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

  def create_data
    @data = SQA::DataFrame::Data.new(ticker: @ticker, source: @source, indicators: { xyzzy: "Magic" })
  end

  def update
    begin
      merge_overview
    rescue => e
      # Log warning but don't fail - overview data is optional
      # Common causes: rate limits, network issues, API errors
      warn "Warning: Could not fetch overview data for #{@ticker} (#{e.class}: #{e.message}). Continuing without it."
    end
  end

  def save_data
    @data_path.write(@data.to_json)
  end

  def_delegators :@data, :ticker, :name, :exchange, :source, :indicators, :indicators=, :overview

  def update_the_dataframe
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
      rescue => e
        # If we can't fetch data, raise a more helpful error
        raise "Unable to fetch data for #{@ticker}. Please ensure API key is set or provide cached CSV file at #{@df_path}. Error: #{e.message}"
      end
    end

    update_dataframe_with_recent_data
  end

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
    rescue => e
      # Log warning but don't fail - we have cached data
      # Common causes: rate limits, network issues, API errors
      warn "Warning: Could not update #{@ticker} from API (#{e.class}: #{e.message}). Using cached data."
    end
  end

  def should_update?
    # Don't update if we're in lazy update mode
    return false if SQA.config.lazy_update

    # Don't update if we don't have an API key (only relevant for Alpha Vantage)
    if @source == :alpha_vantage
      begin
        SQA.av_api_key
      rescue
        return false
      end
    end

    # Don't update if CSV data is already current (last timestamp is today or later)
    # This prevents unnecessary API calls when we already have today's data
    if @df && @df.size > 0
      begin
        last_timestamp = Date.parse(@df["timestamp"].to_a.last)
        return false if last_timestamp >= Date.today
      rescue => e
        # If we can't parse the date, assume we need to update
        warn "Warning: Could not parse last timestamp for #{@ticker} (#{e.message}). Will attempt update." if $VERBOSE
      end
    end

    true
  end

  def to_s
    "#{ticker} with #{@df.size} data points from #{@df["timestamp"].to_a.first} to #{@df["timestamp"].to_a.last}"
  end
  # Note: CSV data is stored in ascending chronological order (oldest to newest)
  # This ensures compatibility with TA-Lib indicators which expect arrays in this order
  alias_method :inspect, :to_s

  def merge_overview
    temp = JSON.parse(
      CONNECTION.get("/query?function=OVERVIEW&symbol=#{ticker.upcase}&apikey=#{SQA.av.key}")
      .to_hash[:body]
    )

    if temp.has_key? "Information"
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
    def top
      return @@top unless @@top.nil?

      a_hash = JSON.parse(CONNECTION.get("/query?function=TOP_GAINERS_LOSERS&apikey=#{SQA.av.key}").to_hash[:body])

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

      @@top = mash
    end
  end
end
