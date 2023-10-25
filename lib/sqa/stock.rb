# lib/sqa/stock.rb


# SMELL:  SQA::Stock is now pretty coupled to the Alpha Vantage
#         API service.  Should that stuff be extracted into a
#         separate class and injected by the requiring program?

class SQA::Stock
  extend Forwardable

  CONNECTION = Faraday.new(url: "https://www.alphavantage.co")

  attr_accessor :data # General Info      -- SQA::DataFrame::Data
  attr_accessor :df   # Historical Prices -- SQA::DataFrame::Data

  attr_accessor :klass        # class of historical and current prices
  attr_accessor :transformers # procs for changing column values from String to Numeric

  def initialize(
        ticker:,
        source: :alpha_vantage
      )

    @ticker     = ticker.downcase
    @source     = source

    raise "Invalid Ticker #{ticker}" unless SQA::Ticker.valid?(ticker)

    @data_path  = SQA.data_dir + "#{@ticker}.json"
    @df_path    = SQA.data_dir + "#{@ticker}.csv"

    @klass         = "SQA::DataFrame::#{@source.to_s.camelize}".constantize
    @transformers  = "SQA::DataFrame::#{@source.to_s.camelize}::TRANSFORMERS".constantize

    if @data_path.exist?
      load
    else
      create
      update
      save
    end

    update_the_dataframe
  end


  def load
    @data = SQA::DataFrame::Data.new(
              JSON.parse(@data_path.read)
            )
  end


  def create
    @data =
      SQA::DataFrame::Data.new(
        {
          ticker:       @ticker,
          source:       @source,
          indicators:   { xyzzy: "Magic" },
        }
      )
  end


  def update
    merge_overview
  end


  def save
    @data_path.write @data.to_json
  end


  def_delegator :@data, :ticker,      :ticker
  def_delegator :@data, :name,        :name
  def_delegator :@data, :exchange,    :exchange
  def_delegator :@data, :source,      :source
  def_delegator :@data, :indicators,  :indicators
  def_delegator :@data, :indicators=, :indicators=
  def_delegator :@data, :overview,    :overview



  def update_the_dataframe
    if @df_path.exist?
      @df     = SQA::DataFrame.load(
        source:       @df_path,
        transformers: @transformers
      )
    else
      @df     = klass.recent(@ticker, full: true)
      @df.to_csv(@df_path)
      return
    end

    from_date = Date.parse(@df.timestamp.last) + 1
    df2       = klass.recent(@ticker, from_date: from_date)

    return if df2.nil?  # CSV file is up to date.

    df_nrows  = @df.nrows
    @df.append!(df2)

    if @df.nrows > df_nrows
      @df.to_csv(@df_path)
    end
  end


  def to_s
    "#{ticker} with #{@df.size} data points from #{@df.timestamp.first} to #{@df.timestamp.last}"
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

    # TODO: CamelCase hash keys look common in Alpha Vantage
    #       JSON; look at making a special Hashie-based class
    #       to convert the keys to normal Ruby standards.

    temp2 = {}

    string_values = %w[ address asset_type cik country currency
                        description dividend_date ex_dividend_date
                        exchange fiscal_year_end industry latest_quarter
                        name sector symbol
                      ]

    temp.keys.each do |k|
      new_k         = k.underscore
      temp2[new_k]  = string_values.include?(new_k) ? temp[k] : temp[k].to_f
    end

    @data.overview = temp2
  end


  #############################################
  ## Class Methods

  class << self
    @@top = nil

    # Top Gainers, Losers and Most Active for most
    # recent closed trading day.
    #
    def top
      return @@top unless @@top.nil?

      a_hash  = JSON.parse(
                  CONNECTION.get(
                    "/query?function=TOP_GAINERS_LOSERS&apikey=#{SQA.av.key}"
                  ).to_hash[:body]
                )

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
