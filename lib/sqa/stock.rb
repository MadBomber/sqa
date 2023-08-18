# lib/sqa/stock.rb

class SQA::Stock
  attr_accessor :company_name
  attr_accessor :df             # The DataFrane
  attr_accessor :ticker

  def initialize(ticker:, source: :yahoo_finance, type: :csv)
    @ticker       = ticker.downcase
    @company_name = "Company Name"
    klass         = "SQA::DataFrame::#{source.to_s.camelize}".constantize
    filename      = "#{@ticker}.#{type}"
    @df           = klass.send(:load, filename)
    @df[:ticker]  = ticker
  end

  def to_s
    "#{ticker} with #{@df.size} data points from #{@df.timestamp.first} to #{@df.timestamp.last}"
  end
end

__END__

aapl = Stock.new('aapl', SQA::Datastore::CSV)
