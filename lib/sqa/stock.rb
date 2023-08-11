# lib/sqa/stock.rb

require_relative 'indicators'
require_relative 'datastore/csv'

class SQA::Stock
  include SQA::Indicators

  attr_accessor :company_name
  attr_accessor :data
  attr_accessor :ticker

  def initialize(ticker, datastore = Datastore::CSV)
    @ticker       = ticker
    @company_name = "Company Name"
    @data         = datastore.new(ticker)
  end
end

__END__

aapl = Stock.new('aapl', SQA::Datastore::CSV)