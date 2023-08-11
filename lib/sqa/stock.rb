# lib/sqa/stock.rb

require_relative 'indicators'
require_relative 'datastore'

class SQA::Stock < ActiveRecord::Base
  include SQA::Indicators

  # has_many :activities using ticker as the foreign key
  # primary id is ticker  it is unique

  attr_accessor :company_name
  attr_accessor :data
  attr_accessor :ticker

  def initialize(ticker, datastore = SQA::Datastore::CSV)
    @ticker       = ticker
    @company_name = "Company Name"
    @data         = datastore.new(ticker)
  end

  def to_s
    "#{ticker} with #{@data.size} data points."
  end
end

__END__

aapl = Stock.new('aapl', SQA::Datastore::CSV)
