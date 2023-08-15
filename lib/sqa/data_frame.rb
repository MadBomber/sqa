# lib/sqa/data_frame.rb
# frozen_string_literal: true

require_relative  'data_frame/yahoo_finance'

class SQA::DataFrame < Daru::DataFrame
  def self.from_csv(path_to_csv_file)
    super(path_to_csv_file)
  end
end
