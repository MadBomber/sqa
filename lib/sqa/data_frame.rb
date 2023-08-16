# lib/sqa/data_frame.rb
# frozen_string_literal: true

require_relative  'data_frame/yahoo_finance'

class SQA::DataFrame < Daru::DataFrame
  def self.from_csv(ticker)
    path_to_csv = SQA::Config.data_dir + "#{ticker.downcase}.csv"
    super(path_to_csv)
  end
end
