# lib/sqa/data_frame.rb
# frozen_string_literal: true

require 'forwardable'

require_relative 'data_frame/yahoo_finance'
require_relative 'data_frame/alpha_vantage'

class SQA::DataFrame
  extend Forwardable

  attr_accessor :data

  def initialize(a_hash)
    @data = Hashie::Mash.new(a_hash)
  end

  def_delegator :@data, :to_csv, :to_csv

  def to_json(path_to_file)
    raise NotImplemented
  end

  def to_aofh
    raise NotImplemented
  end

  def_delegator :@data, :to_h, :to_hofa
  alias_method :to_h, :to_hofa

  def_delegator :@data, :size
  alias_method :nrows, :size
  alias_method :length, :size

  def_delegator :@data, :keys
  alias_method :vectors, :keys
  alias_method :columns, :keys

  def_delegator :@data, :values, :values
  def_delegator :@data, :[], :[]
  def_delegator :@data, :[]=, :[]=

  def rows
    result = []
    (0..size - 1).each do |x|
      entry = row(x)
      result << entry
    end
    result
  end
  alias_method :to_a, :rows

  def row(x)
    raise SQA::BadParameterError if x < 0 || x >= size

    entry = []
    keys.each do |key|
      entry << @data[key][x]
    end
    entry
  end

  #################################################
  def self.load(ticker, type="csv", options={}, &block)
    source  = SQA.data_dir + "#{ticker}.#{type}"

    if :csv == type
      from_csv_file(source)
    elsif :json == type
      from_json_file(source)
    else
      raise SQA::BadParameterError, "un-supported file type: #{type}"
    end
  end

  def from_csv_file(source)
    raise NotImplemented
  end

  def from_json_file(source)
    raise NotImplemented
  end

  # aofh -- Array of Hashes
  # hofa == Hash of Arrays
  def aofh_to_hofa(aofh)
    result = {}

    keys = aofh.first.keys

    keys.each do |key|
      result[key] = []
    end

    aofh.each do |entry|
      keys.each do |key|
        result[key] << entry[key]
      end
    end

    result
  end

  # TODO: Add the normalize key methods
end


