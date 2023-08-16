# lib/sqa/data_frame.rb
# frozen_string_literal: true

require_relative  'data_frame/yahoo_finance'

class SQA::DataFrame < Daru::DataFrame
  def self.path(filename)
    SQA::Config.data_dir + filename
  end

  def self.from_csv(ticker)
    df          = super(path("#{ticker.downcase}.csv"))
    df[:ticker] = ticker
    df
  end
end
