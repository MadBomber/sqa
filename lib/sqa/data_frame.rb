# lib/sqa/data_frame.rb
# frozen_string_literal: true

require_relative  'data_frame/yahoo_finance'

class SQA::DataFrame < Daru::DataFrame
  def self.path(filename)
    SQA::Config.data_dir + filename
  end

  def self.load(filename, options={}, &block)
    source  = path(filename)
    type    = source.extname.downcase

    if ".csv" == type
     from_csv(source, options={}, &block)
    elsif ".json" == type
      from_json(source, options={}, &block)
    elsif %w[.txt .dat].include?(type)
      from_plaintext(source, options={}, &block)
    elsif ".xls" == type
      from_excel(source, options={}, &block)
    else
      raise SQA::BadParamenterError, "un-suppod file type: #{type}"
    end
  end
end
