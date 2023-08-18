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

  def self.load(filename)
    source  = path(filename)
    type    = source.extname.downcase

    if ".csv" == type
      @df = Daru::DataFrame.from_csv(source)
    elsif ".json" == type
      @df = Daru::DataFrame.from_json(source)
    else
      raise SQA::BadParamenterError, "supports csv or json only"
    end
  end
end
