# lib/sqa/stock.rb

require 'active_support/core_ext/string' # for String#underscore
require 'hashie' # for Hashie::Mash


# SMELL:  SQA::Stock is now pretty coupled to the Alpha Vantage
#         API service.  Should that stuff be extracted into a
#         separate class and injected by the requiring program?

class SQA::Stock
  CONNECTION = Faraday.new(url: "https://www.alphavantage.co")

  attr_accessor :company_name
  attr_accessor :df             # The DataFrane
  attr_accessor :ticker
  attr_accessor :type           # type of data store (default is CSV)
  attr_accessor :indicators

  def initialize(
        ticker:,
        source: :alpha_vantage,
        type:   :csv
      )
    raise "Invalid Ticker #{ticker}" unless SQA::Ticker.valid?(ticker)

    # TODO: Change API on lookup to return array instead of hash
    #       Could this also incorporate the validation process to
    #       save an additiona hash lookup?

    entry         = SQA::Ticker.lookup(ticker)

    @ticker       = ticker.downcase
    @company_name = entry[:name]
    @exchange     = entry[:exchange]
    @klass        = "SQA::DataFrame::#{source.to_s.camelize}".constantize
    @type         = type
    @indicators   = OpenStruct.new

    update_the_dataframe
  end


  def update_the_dataframe
    df1 = @klass.load(@ticker, type)
    df2 = @klass.recent(@ticker)

    df1_nrows = df1.nrows
    @df       = @klass.append(df1, df2)

    if @df.nrows > df1_nrows
      @df.send("to_#{@type}", SQA.data_dir + "#{ticker}.csv")
    end

    # Adding a ticker vector in case I want to do
    # some multi-stock analysis in the same data frame.
    # For example to see how one stock coorelates with another.
    @df[:ticker]  = @ticker
  end

  def to_s
    "#{ticker} with #{@df.size} data points from #{@df.timestamp.first} to #{@df.timestamp.last}"
  end

  # TODO: Turn this into a class Stock::Overview
  #       which is a sub-class of Hashie::Dash
  def overview
    return @overview unless @overview.nil?

    temp = JSON.parse(
      CONNECTION.get("/query?function=OVERVIEW&symbol=#{@ticker.upcase}&apikey=#{Nenv.av_api_key}")
        .to_hash[:body]
    )

    # TODO: CamelCase hash keys look common in Alpha Vantage
    #       JSON; look at making a special Hashie-based class
    #       to convert the keys to normal Ruby standards.

    temp2 = {}

    string_values = %w[ address asset_type cik country currency description dividend_date ex_dividend_date exchange fiscal_year_end industry latest_quarter name sector symbol ]

    temp.keys.each do |k|
      new_k         = k.underscore
      temp2[new_k]  = string_values.include?(new_k) ? temp[k] : temp[k].to_f
    end

    @overview = Hashie::Mash.new temp2
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

      mash = Hashie::Mash.new(
        JSON.parse(
          CONNECTION.get(
            "/query?function=TOP_GAINERS_LOSERS&apikey=#{Nenv.av_api_key}"
          ).to_hash[:body]
        )
      )

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
