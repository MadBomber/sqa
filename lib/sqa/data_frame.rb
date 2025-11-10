# lib/sqa/data_frame.rb
# frozen_string_literal: true

require 'forwardable'
require 'csv'
require 'polars'


require_relative 'data_frame/data'
require_relative 'data_frame/yahoo_finance'
require_relative 'data_frame/alpha_vantage'

class SQA::DataFrame
  extend Forwardable

  attr_accessor :data

  def initialize(raw_data = nil, mapping: {}, transformers: {})
    @data = if raw_data
              Polars::DataFrame.new(raw_data)
            else
              Polars::DataFrame.new([])
            end

    apply_transformers!(transformers) unless transformers.empty?
    rename_columns!(mapping) unless mapping.empty?
  end

  def apply_transformers!(transformers)
    transformers.each do |col, transformer|
      col_name = col.to_s
      @data = @data.with_column(
        @data[col_name].apply(&transformer).alias(col_name)
      )
    end
  end

  def rename_columns!(mapping)
    rename_mapping = @data.columns.each_with_index.map do |col, _|
      [col, mapping[col.downcase.to_sym] || col]
    end.to_h
    @data = @data.rename(rename_mapping)
  end

  def append!(other_df)
    self_row_count = @data.shape[0]
    other_row_count = other_df.data.shape[0]

    if self_row_count == 0
      @data = other_df.data
    else
      @data = @data.vstack(other_df.data)
    end

    post_append_row_count = @data.shape[0]
    expected_row_count = self_row_count + other_row_count
    raise "Append Error: expected #{expected_row_count}, got #{post_append_row_count} " unless post_append_row_count == expected_row_count
  end
  alias concat! append!

  def columns
    @data.columns
  end

  def keys
    @data.columns
  end
  alias vectors keys

  def to_h
    @data.columns.map { |col| [col.to_sym, @data[col].to_a] }.to_h
  end

  def to_csv(path_to_file)
    @data.write_csv(path_to_file)
  end

  def size
    @data.height
  end
  alias nrows size
  alias length size

  def ncols
    @data.width
  end

  # FPL Analysis - Calculate Future Period Loss/Profit
  #
  # @param column [String, Symbol] Column name containing prices (default: "adj_close_price")
  # @param fpop [Integer] Future Period of Performance (days to look ahead)
  # @return [Array<Array<Float, Float>>] Array of [min_delta, max_delta] pairs
  #
  # @example
  #   stock = SQA::Stock.new(ticker: 'AAPL')
  #   fpl_data = stock.df.fpl(fpop: 10)
  #
  def fpl(column: "adj_close_price", fpop: 14)
    prices = @data[column.to_s].to_a
    SQA::FPOP.fpl(prices, fpop: fpop)
  end

  # FPL Analysis with risk metrics and classification
  #
  # @param column [String, Symbol] Column name containing prices (default: "adj_close_price")
  # @param fpop [Integer] Future Period of Performance
  # @return [Array<Hash>] Array of analysis hashes
  #
  # @example
  #   analysis = stock.df.fpl_analysis(fpop: 10)
  #   analysis.first[:direction]  # => :UP, :DOWN, :UNCERTAIN, or :FLAT
  #   analysis.first[:magnitude]  # => Average expected movement percentage
  #   analysis.first[:risk]       # => Volatility range
  #
  def fpl_analysis(column: "adj_close_price", fpop: 14)
    prices = @data[column.to_s].to_a
    SQA::FPOP.fpl_analysis(prices, fpop: fpop)
  end

  def self.is_date?(value)
    value.is_a?(String) && !/\d{4}-\d{2}-\d{2}/.match(value).nil?
  end

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
    @data.respond_to?(method_name) || super
  end

  class << self
    def from_aofh(aofh, mapping: {}, transformers: {})
      aoh_sanitized = aofh.map { |entry| entry.transform_keys(&:to_s) }
      columns = aoh_sanitized.first.keys
      data = aoh_sanitized.map(&:values)
      df = Polars::DataFrame.new(
        data,
        columns: columns
      )
      new(df)
    end

    def from_csv_file(source, mapping: {}, transformers: {})
      df = Polars.read_csv(source)
      new(df)
    end

    def from_json_file(source, mapping: {}, transformers: {})
      aofh = JSON.parse(File.read(source)).map { |entry| entry.transform_keys(&:to_s) }
      from_aofh(aofh, mapping: mapping, transformers: transformers)
    end

    def generate_mapping(keys)
      keys.each_with_object({}) do |key, hash|
        hash[key.to_s] = underscore_key(key.to_s)
      end
    end

    def underscore_key(key)
      key.to_s
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .gsub(/[^a-zA-Z0-9]/, ' ')
        .squeeze(' ')
        .strip
        .tr(' ', '_')
        .downcase
        .to_sym
    end

    alias sanitize_key underscore_key

    def normalize_keys(hash, adapter_mapping: {})
      hash = rename(hash, adapter_mapping) unless adapter_mapping.empty?
      mapping = generate_mapping(hash.keys)
      rename(hash, mapping)
    end

    def rename(hash, mapping)
      mapping.each { |old_key, new_key| hash[new_key] = hash.delete(old_key) if hash.key?(old_key) }
      hash
    end

    def aofh_to_hofa(aofh, mapping: {}, transformers: {})
      hofa = Hash.new { |h, k| h[k.downcase] = [] }
      aofh.each { |entry| entry.each { |key, value| hofa[key.to_s.downcase] << value } }
      hofa
    end
  end
end
