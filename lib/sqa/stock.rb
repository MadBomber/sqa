# lib/sqa/stock.rb

class SQA::Stock
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
end
