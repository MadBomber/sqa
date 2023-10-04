# lib/sqa/data_frame.rb
# frozen_string_literal: true

# This is an attempt to make some of the customer code
# 3rd part df agnostic.
#
# TODO: Think about some kind of plugin feature to allow
#       application to choose its own data frame package.
#
SQADF = Rover


require_relative  'data_frame/yahoo_finance'
require_relative  'data_frame/alpha_vantage'


class SQADF::DataFrame
  if "Rover" == SQADF.name
    alias_method :nrows,          :size
    alias_method :rename_vectors, :rename
  elsif "Polars" == SQADF.name
    alias_method :nrows,          :height
    alias_method :first,          :head
    alias_method :last,           :tail
  end
end


class SQA::DataFrame < SQADF::DataFrame

  # Rover does not write CSV files
  def to_csv(a_path)
    buffer = super()
    a_path.write buffer
  end


  #################################################
  def self.load(ticker, type=:csv, options={}, &block)
    if ticker.is_a?(Pathname)
      source  = ticker
      type    = ticker.extname.to_s[1..].to_sym
    else
      source  = SQA.data_dir + "#{ticker}.#{type}"
    end

    if :csv == type
     from_csv(source, options={})
    elsif :json == type
      from_json(source, options={}, &block)
    elsif %i[txt dat].include?(type)
      from_plaintext(source, options={}, &block)
    elsif :xls == type
      from_excel(source, options={}, &block)
    elsif :parquet == type
      from_parquet(source, options)
    else
      raise SQA::BadParameterError, "un-supported file type: #{type}"
    end
  end


  def self.from_csv(source, options={})
    Rover.read_csv(source)
  end


  def self.from_parquet(source, options={})
    Rover.read_parquet(source, options)
  end
end

