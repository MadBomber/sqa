# lib/sqa/stock.rb

class SQA::Stock
  attr_accessor :company_name
  attr_accessor :df             # The DataFrane
  attr_accessor :ticker
  attr_accessor :indicators

  def initialize(ticker:, source: :yahoo_finance, type: :csv)
    @ticker       = ticker.downcase
    @company_name = "Company Name"
    @klass        = "SQA::DataFrame::#{source.to_s.camelize}".constantize
    @type         = type
    @filename     = "#{@ticker}.#{type}"
    @indicators   = OpenStruct.new

    update_the_dataframe
  end


  def update_the_dataframe
    df1 = @klass.load(@filename)
    df2 = @klass.recent(@ticker)
    @df = @klass.append(df1, df2)

    if @df.nrows > df1.nrows
      @df.send("to_#{@type}", SQA::DataFrame.path(@filename))
    end

    # Adding a ticker vector in case I want to do
    # some multi-stock analysis in the same data frame.
    @df[:ticker]  = @ticker
  end

  def to_s
    "#{ticker} with #{@df.size} data points from #{@df.timestamp.first} to #{@df.timestamp.last}"
  end
end

__END__

aapl = Stock.new('aapl', SQA::Datastore::CSV)
