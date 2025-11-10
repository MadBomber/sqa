# lib/sqa/stock.rb

class SQA::Stock
  extend Forwardable

  CONNECTION = Faraday.new(url: "https://www.alphavantage.co")

  attr_accessor :data, :df, :klass, :transformers, :strategy

  def initialize(ticker:, source: :alpha_vantage)
    @ticker = ticker.downcase
    @source = source

    raise "Invalid Ticker #{ticker}" unless SQA::Ticker.valid?(ticker)

    @data_path = SQA.data_dir + "#{@ticker}.json"
    @df_path = SQA.data_dir + "#{@ticker}.csv"

    @klass = "SQA::DataFrame::#{@source.to_s.camelize}".constantize
    @transformers = "SQA::DataFrame::#{@source.to_s.camelize}::TRANSFORMERS".constantize

    load_or_create_data
    update_the_dataframe
  end

  def load_or_create_data
    if @data_path.exist?
      @data = SQA::DataFrame::Data.new(JSON.parse(@data_path.read))
    else
      create_data
      update
      save_data
    end
  end

  def create_data
    @data = SQA::DataFrame::Data.new(ticker: @ticker, source: @source, indicators: { xyzzy: "Magic" })
  end

  def update
    merge_overview
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

      # Migration: Add adj_close_price column if missing (for old cached files)
      # This ensures compatibility when appending new data that includes this column
      migrated = false
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
      @df = @klass.recent(@ticker, full: true)
      @df.to_csv(@df_path)
      return
    end

    update_dataframe_with_recent_data
  end

  def update_dataframe_with_recent_data
    from_date = Date.parse(@df["timestamp"].to_a.last)
    df2 = @klass.recent(@ticker, from_date: from_date)

    if df2 && (df2.size > 0)
      @df.concat!(df2)
      @df.to_csv(@df_path)
    end
  end

  def to_s
    "#{ticker} with #{@df.size} data points from #{@df["timestamp"].to_a.first} to #{@df["timestamp"].to_a.last}"
  end
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
