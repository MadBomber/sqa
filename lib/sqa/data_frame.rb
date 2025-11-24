# lib/sqa/data_frame.rb
# frozen_string_literal: true

require 'forwardable'
require 'csv'
require 'polars'


require_relative 'data_frame/data'
require_relative 'data_frame/yahoo_finance'
require_relative 'data_frame/alpha_vantage'

# High-performance DataFrame wrapper around Polars for time series data manipulation.
# Provides convenience methods for stock market data while leveraging Polars' Rust-backed
# performance for vectorized operations.
#
# @example Creating from CSV
#   df = SQA::DataFrame.load(source: "path/to/data.csv")
#
# @example Creating from array of hashes
#   data = [{ timestamp: "2024-01-01", close: 100.0 }, { timestamp: "2024-01-02", close: 101.5 }]
#   df = SQA::DataFrame.from_aofh(data)
#
# @example Accessing data
#   prices = df["adj_close_price"].to_a
#   df.columns  # => ["timestamp", "open_price", "high_price", ...]
#
class SQA::DataFrame
  extend Forwardable

  # @!attribute [rw] data
  #   @return [Polars::DataFrame] The underlying Polars DataFrame
  attr_accessor :data

  # Creates a new DataFrame instance.
  #
  # @param raw_data [Hash, Array, Polars::DataFrame, nil] Initial data for the DataFrame
  # @param mapping [Hash] Column name mappings to apply (old_name => new_name)
  # @param transformers [Hash] Column transformers to apply (column => lambda)
  #
  # @example With column mapping
  #   df = SQA::DataFrame.new(data, mapping: { "Close" => "close_price" })
  #
  # @example With transformers
  #   df = SQA::DataFrame.new(data, transformers: { "price" => ->(v) { v.to_f } })
  #
  def initialize(raw_data = nil, mapping: {}, transformers: {})
    @data = Polars::DataFrame.new(raw_data || [])

    # IMPORTANT: Rename columns FIRST, then apply transformers
    # Transformers expect renamed column names
    rename_columns!(mapping) unless mapping.empty?
    apply_transformers!(transformers) unless transformers.empty?
  end


  # Applies transformer functions to specified columns in place.
  #
  # @param transformers [Hash{String, Symbol => Proc}] Column name to transformer mapping
  # @return [void]
  #
  # @example
  #   df.apply_transformers!({ "price" => ->(v) { v.to_f }, "volume" => ->(v) { v.to_i } })
  #
  def apply_transformers!(transformers)
    transformers.each do |col, transformer|
      col_name = col.to_s
      @data = @data.with_column(
        @data[col_name].apply(&transformer).alias(col_name)
      )
    end
  end

  # Renames columns according to the provided mapping in place.
  #
  # @param mapping [Hash{String, Symbol => String}] Old column name to new column name mapping
  # @return [void]
  #
  # @example
  #   df.rename_columns!({ "open" => "open_price", "close" => "close_price" })
  #
  def rename_columns!(mapping)
    # Normalize mapping keys to strings for consistent lookup
    # mapping can have string or symbol keys, columns are always strings
    string_mapping = mapping.transform_keys(&:to_s)

    rename_mapping = @data.columns.each_with_index.map do |col, _|
      # Try exact match first, then lowercase match
      new_name = string_mapping[col] || string_mapping[col.downcase] || col
      # Polars requires both keys and values to be strings
      [col, new_name.to_s]
    end.to_h

    @data = @data.rename(rename_mapping)
  end


  # Appends another DataFrame to this one in place.
  #
  # @param other_df [SQA::DataFrame] DataFrame to append
  # @return [void]
  # @raise [RuntimeError] If the resulting row count doesn't match expected
  #
  # @example
  #   df1.append!(df2)
  #
  def append!(other_df)
    self_row_count = @data.shape[0]
    other_row_count = other_df.data.shape[0]

    @data = if self_row_count == 0
              other_df.data
            else
              @data.vstack(other_df.data)
            end

    post_append_row_count = @data.shape[0]
    expected_row_count = self_row_count + other_row_count
    return if post_append_row_count == expected_row_count

    raise "Append Error: expected #{expected_row_count}, got #{post_append_row_count} "

  end
  alias concat! append!

  # Concatenate another DataFrame, remove duplicates, and sort
  # This is the preferred method for updating CSV data to prevent duplicates
  #
  # @param other_df [SQA::DataFrame] DataFrame to append
  # @param sort_column [String] Column to use for deduplication and sorting (default: "timestamp")
  # @param descending [Boolean] Sort order - false for ascending (oldest first, TA-Lib compatible), true for descending
  #
  # NOTE: TA-Lib requires data in ascending (oldest-first) order. Using descending: true
  # will produce a warning and force ascending order to prevent silent calculation errors.
  #
  # @example Merge new data with deduplication
  #   stock = SQA::Stock.new(ticker: 'AAPL')
  #   df = stock.df
  #   df.size  # => 252
  #
  #   # Fetch recent data (may have overlapping dates)
  #   new_df = SQA::DataFrame::AlphaVantage.recent('AAPL', from_date: Date.today - 7)
  #   df.concat_and_deduplicate!(new_df)
  #   # Duplicates removed, data sorted ascending (oldest first)
  #   df.size  # => 255 (only 3 new unique dates added)
  #
  # @example Maintains TA-Lib compatibility
  #   df.concat_and_deduplicate!(new_df)  # Sorted ascending automatically
  #   prices = df["adj_close_price"].to_a
  #   rsi = SQAI.rsi(prices, period: 14)  # Works correctly with ascending data
  #
  def concat_and_deduplicate!(other_df, sort_column: "timestamp", descending: false)
    # Enforce ascending order for TA-Lib compatibility
    if descending
      warn "[SQA WARNING] TA-Lib requires ascending (oldest-first) order. Forcing descending: false"
      descending = false
    end

    # Concatenate the dataframes
    @data = if @data.shape[0] == 0
              other_df.data
            else
              @data.vstack(other_df.data)
            end

    # Remove duplicates based on sort_column, keeping first occurrence
    @data = @data.unique(subset: [sort_column], keep: "first")

    # Sort by the specified column (Polars uses 'reverse' for descending)
    @data = @data.sort(sort_column, reverse: descending)
  end

  # Returns the column names of the DataFrame.
  #
  # @return [Array<String>] List of column names
  def columns
    @data.columns
  end

  # Returns the column names of the DataFrame.
  # Alias for {#columns}.
  #
  # @return [Array<String>] List of column names
  def keys
    @data.columns
  end
  alias vectors keys

  # Converts the DataFrame to a Ruby Hash.
  #
  # @return [Hash{Symbol => Array}] Hash with column names as keys and column data as arrays
  #
  # @example
  #   df.to_h  # => { timestamp: ["2024-01-01", ...], close_price: [100.0, ...] }
  #
  def to_h
    @data.columns.map { |col| [col.to_sym, @data[col].to_a] }.to_h
  end

  # Writes the DataFrame to a CSV file.
  #
  # @param path_to_file [String, Pathname] Path to output CSV file
  # @return [void]
  #
  # @example Save stock data to CSV
  #   stock = SQA::Stock.new(ticker: 'AAPL')
  #   stock.df.to_csv('aapl_prices.csv')
  #
  # @example Export with custom path
  #   df.to_csv(Pathname.new('data/exports/prices.csv'))
  #
  def to_csv(path_to_file)
    @data.write_csv(path_to_file)
  end

  # Returns the number of rows in the DataFrame.
  #
  # @return [Integer] Row count
  def size
    @data.height
  end
  alias nrows size
  alias length size

  # Returns the number of columns in the DataFrame.
  #
  # @return [Integer] Column count
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
  def fpl(column: 'adj_close_price', fpop: 14)
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
  def fpl_analysis(column: 'adj_close_price', fpop: 14)
    prices = @data[column.to_s].to_a
    SQA::FPOP.fpl_analysis(prices, fpop: fpop)
  end


  # Checks if a value appears to be a date string.
  #
  # @param value [Object] Value to check
  # @return [Boolean] true if value matches YYYY-MM-DD format
  def self.is_date?(value)
    value.is_a?(String) && !/\d{4}-\d{2}-\d{2}/.match(value).nil?
  end

  # Delegates unknown methods to the underlying Polars DataFrame.
  # This allows direct access to Polars methods like filter, select, etc.
  #
  # @param method_name [Symbol] Method name being called
  # @param args [Array] Method arguments
  # @param block [Proc] Optional block
  # @return [Object] Result from Polars DataFrame method
  def method_missing(method_name, *args, &block)
    return super unless @data.respond_to?(method_name)
    @data.send(method_name, *args, &block)
  end

  # Checks if the DataFrame responds to a method.
  #
  # @param method_name [Symbol] Method name to check
  # @param include_private [Boolean] Include private methods
  # @return [Boolean] true if method is available
  def respond_to_missing?(method_name, include_private = false)
    @data.respond_to?(method_name) || super
  end

  class << self
    # Load a DataFrame from a file source
    # This is the primary method for loading persisted DataFrames
    #
    # @param source [String, Pathname] Path to CSV file
    # @param transformers [Hash] Column transformations to apply (usually not needed for cached data)
    # @param mapping [Hash] Column name mappings (usually not needed for cached data)
    # @return [SQA::DataFrame] Loaded DataFrame
    #
    # Note: For cached CSV files, transformers and mapping should typically be empty
    # since transformations were already applied when the data was first fetched.
    # We only apply them if the CSV has old-format column names that need migration.
    def load(source:, transformers: {}, mapping: {})
      df = Polars.read_csv(source.to_s)

      # Auto-detect if CSV needs migration (has old column names like "open" instead of "open_price")
      # Only apply mapping if explicitly provided (for migration scenarios)
      new(df, mapping: mapping, transformers: transformers)
    end

    # Creates a DataFrame from an array of hashes.
    #
    # @param aofh [Array<Hash>] Array of hash records
    # @param mapping [Hash] Column name mappings to apply
    # @param transformers [Hash] Column transformers to apply
    # @return [SQA::DataFrame] New DataFrame instance
    #
    # @example
    #   data = [{ "date" => "2024-01-01", "price" => 100.0 }]
    #   df = SQA::DataFrame.from_aofh(data)
    #
    def from_aofh(aofh, mapping: {}, transformers: {})
      return new({}, mapping: mapping, transformers: transformers) if aofh.empty?

      # Sanitize keys to strings and convert to hash of arrays (Polars-compatible format)
      aoh_sanitized = aofh.map { |entry| entry.transform_keys(&:to_s) }
      columns = aoh_sanitized.first.keys

      # Convert array-of-hashes to hash-of-arrays for Polars
      hofa = columns.each_with_object({}) do |col, hash|
        hash[col] = aoh_sanitized.map { |row| row[col] }
      end

      df = Polars::DataFrame.new(hofa)
      new(df, mapping: mapping, transformers: transformers)
    end

    # Creates a DataFrame from a CSV file.
    #
    # @param source [String, Pathname] Path to CSV file
    # @param mapping [Hash] Column name mappings to apply
    # @param transformers [Hash] Column transformers to apply
    # @return [SQA::DataFrame] New DataFrame instance
    def from_csv_file(source, mapping: {}, transformers: {})
      df = Polars.read_csv(source)
      new(df, mapping: mapping, transformers: transformers)
    end

    # Creates a DataFrame from a JSON file.
    #
    # @param source [String, Pathname] Path to JSON file containing array of objects
    # @param mapping [Hash] Column name mappings to apply
    # @param transformers [Hash] Column transformers to apply
    # @return [SQA::DataFrame] New DataFrame instance
    def from_json_file(source, mapping: {}, transformers: {})
      aofh = JSON.parse(File.read(source)).map { |entry| entry.transform_keys(&:to_s) }
      from_aofh(aofh, mapping: mapping, transformers: transformers)
    end

    # Generates a mapping of original keys to underscored keys.
    #
    # @param keys [Array<String>] Original key names
    # @return [Hash{String => Symbol}] Mapping from original to underscored keys
    def generate_mapping(keys)
      keys.each_with_object({}) do |key, hash|
        hash[key.to_s] = underscore_key(key.to_s)
      end
    end

    # Converts a key string to underscored snake_case format.
    #
    # @param key [String] Key to convert
    # @return [Symbol] Underscored key as symbol
    #
    # @example
    #   underscore_key("closePrice")  # => :close_price
    #   underscore_key("Close Price") # => :close_price
    #
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

    # Normalizes all keys in a hash to snake_case format.
    #
    # @param hash [Hash] Hash with keys to normalize
    # @param adapter_mapping [Hash] Optional pre-mapping to apply first
    # @return [Hash] Hash with normalized keys
    def normalize_keys(hash, adapter_mapping: {})
      hash = rename(hash, adapter_mapping) unless adapter_mapping.empty?
      mapping = generate_mapping(hash.keys)
      rename(hash, mapping)
    end

    # Renames keys in a hash according to a mapping.
    #
    # @param hash [Hash] Hash to modify
    # @param mapping [Hash] Old key to new key mapping
    # @return [Hash] Modified hash
    def rename(hash, mapping)
      mapping.each { |old_key, new_key| hash[new_key] = hash.delete(old_key) if hash.key?(old_key) }
      hash
    end

    # Converts array of hashes to hash of arrays format.
    #
    # @param aofh [Array<Hash>] Array of hash records
    # @param mapping [Hash] Column name mappings (unused, for API compatibility)
    # @param transformers [Hash] Column transformers (unused, for API compatibility)
    # @return [Hash{String => Array}] Hash with column names as keys and arrays as values
    def aofh_to_hofa(aofh, mapping: {}, transformers: {})
      hofa = Hash.new { |h, k| h[k.downcase] = [] }
      aofh.each { |entry| entry.each { |key, value| hofa[key.to_s.downcase] << value } }
      hofa
    end
  end
end
