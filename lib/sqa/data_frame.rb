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


class Rover::DataFrame

  alias_method :nrows, :size

  def rename_vectors(a_hash)
    old_keys = keys.sort
    new_keys = a_hash.values.sort

    return if old_keys == new_keys

    if old_keys == new_keys.map(&:to_s)
      # Change the mapping from string to symbol
      a_hash2 = {}
      new_keys.each do |v_sym|
        a_hash2[v_sym.to_s] = v_sym
      end
      a_hash = a_hash2
    end

    rename(a_hash)
  end


  # create accessor method like Hashie
  def method_missing(method_name)
    define_method method_name do
      self[method_name]
    end
  end
end


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
    Rover.read_csv(source)
  end


  def self.from_parquet(source, options={})
    Rover.read_parquet(source, options)
  end
end
