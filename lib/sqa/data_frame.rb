# lib/sqa/data_frame.rb
# frozen_string_literal: true

# TODO: Consider replacing Daru::Dataframe with
#       rover which is used by prophet.

require_relative  'data_frame/yahoo_finance'
require_relative  'data_frame/alpha_vantage'

# class Daru::DataFrame

#   def to_csv(path_to_file, opts={})
#     options = {
#       headers:    true,
#       converters: :numeric
#     }.merge(opts)

#     writer = ::CSV.open(path_to_file, 'wb')

#     writer << vectors.to_a if options[:headers]

#     each_row do |row|
#       writer << if options[:convert_comma]
#                   row.map { |v| v.to_s.tr('.', ',') }
#                 else
#                   row.to_a
#                 end
#     end

#     writer.close
#   end
# end




class SQA::DataFrame < Rover::DataFrame

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
    Rover.read_csv(source, options)
  end


  def self.from_parquet(source, options={})
    Rover.read_parquet(source, options)
  end
end
