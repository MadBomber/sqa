# lib/sqa/data_frame.rb
# frozen_string_literal: true

require 'forwardable'

require_relative 'data_frame/yahoo_finance'
require_relative 'data_frame/alpha_vantage'

class SQA::DataFrame
  class Data < Hashie::Mash
    # SNELL: Are all of these needed?
    include Hashie::Extensions::Mash::KeepOriginalKeys
    # include Hashie::Extensions::Mash::PermissiveRespondTo
    include Hashie::Extensions::Mash::SafeAssignment
    include Hashie::Extensions::Mash::SymbolizeKeys
    # include Hashie::Extensions::Mash::DefineAccessors
  end

  extend Forwardable

  # @data is of class Data
  attr_accessor :data

  # Expects a Hash of Arrays (hofa)
  def initialize(a_hash={})
    @data = Data.new(a_hash)
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


  # The number of data rows
  def size
    data[@data.keys[0]].size
  end
  alias_method :nrows,  :size
  alias_method :length, :size


  def_delegator :@data,  :keys
  alias_method :vectors, :keys
  alias_method :columns, :keys


  def ncols
    keys.size
  end


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
    if x.is_a?(Integer)
      raise BadParameterError if x < 0 || x >= size

    elsif x.is_a?(Hash)
      raise BadParameterError, "x is #{x}" if x.size > 1
      key = x.keys[0]
      x   = @data[key].index(x[key])
      raise BadParameterError, 'Not Found #{x}' if x.nil?
      return keys.zip(row(x)).to_h

    else
      raise BadParameterError, "Unknown x.class: #{x.class}"
    end

    entry = []

    keys.each do |key|
      entry << @data[key][x]
    end

    entry
  end


  def append(df)
    raise NotImplemented
  end
  alias_method :concat, :append


  # Creates a new instance with new keys
  # based on the mapping hash where
  #   { old_key => new_key }
  #
  def rename(mapping)
    SQA::DataFrame.new(
      self.class.rename(
        mapping,
        @data.to_h
      )
    )
  end
  alias_method :rename_vectors, :rename


  def method_missing(method_name, *args, &block)
    if @data.respond_to?(method_name)
      self.class.send(:define_method, method_name) do |*method_args, &method_block|
        @data.send(method_name, *method_args, &method_block)
      end
      send(method_name, *args, &block)
    else
      super
    end
  end


  def respond_to_missing?(method_name, include_private = false)
    debug_me('TWO'){[
      :method_name,
      "method_name.class"
    ]}

    @data.respond_to?(method_name) || super
  end

  #################################################
  class << self

    def append(base_df, other_df)
      base_df.append(other_df)
    end


    # TODO: The Data class has its own load which also supports
    #       YAML by default.  Maybe this method should
    #       make use of @data = Data.load(source)
    #
    def load(ticker, type=:csv, options={}, &block)
      if ticker.is_a?(Pathname)
        source  = ticker
        type    = ticker.extname[1..].to_sym
      else
        source  = SQA.data_dir + "#{ticker}.#{type}"
      end

      if :csv == type
        from_csv_file(source)
      elsif :json == type
        from_json_file(source)
      else
        raise BadParameterError, "un-supported file type: #{type}"
      end
    end


    def from_aofh(aofh)
      new(aofh_to_hofa(aofh))
    end


    def from_csv_file(source)
      aofh = []

      CSV.foreach(source, headers: true) do |row|
        aofh << row.to_h
      end

      from_aofh(aofh)
    end


    def from_json_file(source)
      aofh = JSON.parse(source.read)

      from_aofh(aofh)
    end


    # aofh -- Array of Hashes
    # hofa -- Hash of Arrays
    def aofh_to_hofa(aofh)
      hofa = {}
      keys = aofh.first.keys

      keys.each do |key|
        hofa[key] = []
      end

      aofh.each do |entry|
        keys.each do |key|
          hofa[key] << entry[key]
        end
      end

      # SMELL: This might be necessary
      normalize_keys(hofa)

      # hofa
    end


    def normalize_keys(hofa)
      mapping = generate_mapping(hofa.keys)
      rename(mapping, hofa)
    end


    def rename(mapping, hofa)
      mapping.each_pair do |old_key, new_key|
        hofa[new_key] = hofa.delete(old_key)
      end

      hofa
    end


    def generate_mapping(keys)
      mapping = {}

      keys.each do |key|
        mapping[key] = underscore_key(sanitize_key(key)) unless key.is_a?(Symbol)
      end

      mapping
    end


    # returns a snake_case Symbol
    def underscore_key(key)
      key.to_s.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase.to_sym
    end


    # removes punctuation and specal characters,
    # replaces space with underscore.
    def sanitize_key(key)
      key.tr('.():/','').gsub(/^\d+.?\s/, "").tr(' ','_')
    end


    # returns true if key is in a date format
    # like 2023-06-03
    def is_date?(key)
      !/(\d{4}-\d{2}-\d{2})/.match(key.to_s).nil?
    end
  end
end

