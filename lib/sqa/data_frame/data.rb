# lib/sqa/data_frame/data.rb
# frozen_string_literal: true

require 'json'

class SQA::DataFrame
  # Data class to store stock metadata
  #
  # This class holds metadata about a stock including its ticker symbol,
  # name, exchange, data source, technical indicators, and company overview.
  #
  # @example Creating from named parameters
  #   data = SQA::DataFrame::Data.new(
  #     ticker: 'AAPL',
  #     source: :alpha_vantage,
  #     indicators: { rsi: [30, 70], sma: [20, 50] }
  #   )
  #
  # @example Creating from hash (JSON)
  #   json_data = JSON.parse(File.read('stock_data.json'))
  #   data = SQA::DataFrame::Data.new(json_data)
  #
  class Data
    attr_accessor :ticker, :name, :exchange, :source, :indicators, :overview

    # Initialize stock metadata
    #
    # Can be called in two ways:
    #   1. With a hash: SQA::DataFrame::Data.new(hash) - for JSON deserialization
    #   2. With keyword args: SQA::DataFrame::Data.new(ticker: 'AAPL', source: :alpha_vantage, ...)
    #
    # @param data_hash [Hash, nil] Hash of all attributes (when passed as first positional arg)
    # @param ticker [String, Symbol, nil] Ticker symbol
    # @param name [String, nil] Stock name
    # @param exchange [String, nil] Exchange symbol (e.g., 'NASDAQ', 'NYSE')
    # @param source [Symbol] Data source (:alpha_vantage, :yahoo_finance)
    # @param indicators [Hash] Technical indicators configuration
    # @param overview [Hash] Company overview data
    #
    def initialize(data_hash = nil, ticker: nil, name: nil, exchange: nil, source: :alpha_vantage, indicators: {}, overview: {})
      if data_hash.is_a?(Hash) && ticker.nil?
        # Initialize from hash (JSON deserialization) - called as: new(hash)
        @ticker = data_hash['ticker'] || data_hash[:ticker]
        @name = data_hash['name'] || data_hash[:name]
        @exchange = data_hash['exchange'] || data_hash[:exchange]
        @source = data_hash['source'] || data_hash[:source] || source
        @indicators = data_hash['indicators'] || data_hash[:indicators] || {}
        @overview = data_hash['overview'] || data_hash[:overview] || {}

        # Convert source to symbol if it's a string
        @source = @source.to_sym if @source.is_a?(String)
      else
        # Initialize from named parameters - called as: new(ticker: 'AAPL', ...)
        @ticker = ticker
        @name = name
        @exchange = exchange
        @source = source
        @indicators = indicators
        @overview = overview
      end
    end

    # Serialize to JSON string
    #
    # @return [String] JSON representation
    def to_json(*args)
      to_h.to_json(*args)
    end

    # Convert to hash
    #
    # @return [Hash] Hash representation
    def to_h
      {
        ticker: @ticker,
        name: @name,
        exchange: @exchange,
        source: @source,
        indicators: @indicators,
        overview: @overview
      }
    end

    # String representation
    #
    # @return [String] Human-readable representation
    def to_s
      "#{@ticker || 'Unknown'} (#{@exchange || 'N/A'}) via #{@source}"
    end
    alias_method :inspect, :to_s
  end
end
