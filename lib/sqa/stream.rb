# frozen_string_literal: true

require 'thread'

=begin

Real-Time Stock Price Stream Processor

This module provides real-time processing of stock price updates,
calculating indicators on-the-fly and generating trading signals
as new market data arrives.

Key Features:
- Event-driven architecture for live data processing
- Rolling window of recent prices and indicators
- On-demand indicator calculation
- Strategy execution on price updates
- Thread-safe operations
- Callback system for signal notifications

Example:
  stream = SQA::Stream.new(
    ticker: 'AAPL',
    window_size: 100,
    strategies: [SQA::Strategy::RSI, SQA::Strategy::MACD]
  )

  # Add callback for signals
  stream.on_signal do |signal, data|
    puts "Signal: #{signal} at price #{data[:price]}"
  end

  # Feed live price data
  stream.update(price: 150.25, volume: 1_000_000, timestamp: Time.now)

=end

module SQA
  class Stream
    attr_reader :ticker, :window_size, :strategies, :data_buffer, :indicator_cache

    def initialize(ticker:, window_size: 100, strategies: [])
      @ticker = ticker
      @window_size = window_size
      @strategies = Array(strategies)
      @signal_callbacks = []
      @update_callbacks = []

      # Thread-safe data structures
      @mutex = Mutex.new
      @data_buffer = {
        prices: [],
        volumes: [],
        highs: [],
        lows: [],
        timestamps: []
      }

      @indicator_cache = {}
      @last_signal = :hold
      @update_count = 0
    end

    # Add a strategy to the stream processor
    def add_strategy(strategy)
      @mutex.synchronize do
        @strategies << strategy
      end
      self
    end

    # Register callback for trading signals
    #
    # Example:
    #   stream.on_signal do |signal, data|
    #     puts "#{signal.upcase} at $#{data[:price]}"
    #   end
    def on_signal(&block)
      @signal_callbacks << block
      self
    end

    # Register callback for price updates
    #
    # Example:
    #   stream.on_update do |data|
    #     puts "Price updated: $#{data[:price]}"
    #   end
    def on_update(&block)
      @update_callbacks << block
      self
    end

    # Update stream with new market data
    #
    # Required fields: price
    # Optional fields: volume, high, low, timestamp
    def update(price:, volume: nil, high: nil, low: nil, timestamp: Time.now)
      @mutex.synchronize do
        # Add to buffers
        @data_buffer[:prices] << price.to_f
        @data_buffer[:volumes] << (volume || 0).to_f
        @data_buffer[:highs] << (high || price).to_f
        @data_buffer[:lows] << (low || price).to_f
        @data_buffer[:timestamps] << timestamp

        # Trim buffers to window size
        trim_buffers

        # Clear indicator cache (will be recalculated on demand)
        @indicator_cache.clear

        @update_count += 1
      end

      # Prepare update data
      update_data = {
        price: price,
        volume: volume,
        high: high,
        low: low,
        timestamp: timestamp,
        count: @update_count
      }

      # Notify update callbacks
      @update_callbacks.each { |callback| callback.call(update_data) }

      # Process strategies if we have enough data
      process_strategies if sufficient_data?

      true
    end

    # Get current price
    def current_price
      @mutex.synchronize { @data_buffer[:prices].last }
    end

    # Get recent prices
    def recent_prices(count = nil)
      @mutex.synchronize do
        count ? @data_buffer[:prices].last(count) : @data_buffer[:prices].dup
      end
    end

    # Get recent volumes
    def recent_volumes(count = nil)
      @mutex.synchronize do
        count ? @data_buffer[:volumes].last(count) : @data_buffer[:volumes].dup
      end
    end

    # Calculate or retrieve cached indicator
    #
    # Example:
    #   rsi = stream.indicator(:rsi, period: 14)
    #   sma = stream.indicator(:sma, period: 20)
    def indicator(name, **options)
      cache_key = [name, options].hash

      @mutex.synchronize do
        return @indicator_cache[cache_key] if @indicator_cache.key?(cache_key)

        prices = @data_buffer[:prices].dup
        volumes = @data_buffer[:volumes].dup
        highs = @data_buffer[:highs].dup
        lows = @data_buffer[:lows].dup

        result = calculate_indicator(name, prices, volumes, highs, lows, **options)
        @indicator_cache[cache_key] = result
        result
      end
    end

    # Get current trading signal from last strategy execution
    def current_signal
      @last_signal
    end

    # Get statistics about the stream
    def stats
      @mutex.synchronize do
        {
          ticker: @ticker,
          updates: @update_count,
          buffer_size: @data_buffer[:prices].size,
          window_size: @window_size,
          current_price: @data_buffer[:prices].last,
          price_range: price_range,
          last_signal: @last_signal,
          strategies: @strategies.size,
          callbacks: @signal_callbacks.size
        }
      end
    end

    # Reset the stream (clear all data)
    def reset
      @mutex.synchronize do
        @data_buffer.each { |_, v| v.clear }
        @indicator_cache.clear
        @last_signal = :hold
        @update_count = 0
      end
      self
    end

    private

    # Check if we have enough data to run strategies
    def sufficient_data?
      @data_buffer[:prices].size >= 30 # Minimum data points
    end

    # Trim buffers to maintain window size
    def trim_buffers
      @data_buffer.each do |key, buffer|
        buffer.shift while buffer.size > @window_size
      end
    end

    # Process all strategies with current data
    def process_strategies
      return if @strategies.empty?

      # Build vector with current market data and indicators
      vector = build_vector

      # Execute each strategy
      signals = @strategies.map do |strategy|
        begin
          if strategy.is_a?(Class)
            strategy.trade(vector)
          elsif strategy.respond_to?(:call)
            strategy.call(vector)
          else
            :hold
          end
        rescue => e
          puts "Warning: Strategy #{strategy} failed: #{e.message}"
          :hold
        end
      end

      # Determine consensus signal
      signal = consensus_signal(signals)

      # Only emit if signal changed
      if signal != @last_signal
        @last_signal = signal

        signal_data = {
          signal: signal,
          price: current_price,
          timestamp: @data_buffer[:timestamps].last,
          strategies_vote: signals.tally
        }

        # Notify signal callbacks
        @signal_callbacks.each { |callback| callback.call(signal, signal_data) }
      end
    end

    # Build data vector for strategy execution
    def build_vector
      require 'ostruct'

      prices = @data_buffer[:prices].dup
      volumes = @data_buffer[:volumes].dup
      highs = @data_buffer[:highs].dup
      lows = @data_buffer[:lows].dup

      OpenStruct.new(
        ticker: @ticker,
        prices: prices,
        volumes: volumes,
        highs: highs,
        lows: lows,
        current_price: prices.last,

        # Common indicators (lazy calculated)
        rsi: lazy_indicator(:rsi, prices, period: 14),
        sma: lazy_indicator(:sma, prices, period: 20),
        ema: lazy_indicator(:ema, prices, period: 20),
        macd: lazy_indicator(:macd, prices),
        stoch_k: lazy_indicator(:stoch, highs, lows, prices, &:first),
        stoch_d: lazy_indicator(:stoch, highs, lows, prices, &:last),
        bb_upper: lazy_indicator(:bbands, prices, &:first),
        bb_middle: lazy_indicator(:bbands, prices) { |r| r[1] },
        bb_lower: lazy_indicator(:bbands, prices) { |r| r[2] }
      )
    end

    # Lazy indicator calculation (only if accessed)
    def lazy_indicator(name, *args, **kwargs, &extractor)
      lambda do
        result = calculate_indicator(name, *args, **kwargs)
        extractor ? extractor.call(result) : result
      end.call
    rescue => e
      nil
    end

    # Calculate technical indicator
    def calculate_indicator(name, prices, volumes = nil, highs = nil, lows = nil, **options)
      case name
      when :rsi
        SQAI.rsi(prices, **options)
      when :sma
        SQAI.sma(prices, **options)
      when :ema
        SQAI.ema(prices, **options)
      when :macd
        SQAI.macd(prices, **options)
      when :stoch
        SQAI.stoch(highs, lows, prices, **options)
      when :bbands
        SQAI.bbands(prices, **options)
      when :adx
        SQAI.adx(highs, lows, prices, **options)
      when :atr
        SQAI.atr(highs, lows, prices, **options)
      else
        # Try to call indicator directly
        if SQAI.respond_to?(name)
          SQAI.send(name, prices, **options)
        else
          raise "Unknown indicator: #{name}"
        end
      end
    end

    # Determine consensus signal from multiple strategy outputs
    def consensus_signal(signals)
      votes = signals.tally
      buy_votes = votes[:buy] || 0
      sell_votes = votes[:sell] || 0
      hold_votes = votes[:hold] || 0

      # Majority wins
      if buy_votes > sell_votes && buy_votes > hold_votes
        :buy
      elsif sell_votes > buy_votes && sell_votes > hold_votes
        :sell
      else
        :hold
      end
    end

    # Calculate price range in buffer
    def price_range
      prices = @data_buffer[:prices]
      return nil if prices.empty?

      min = prices.min
      max = prices.max
      { min: min, max: max, range: max - min }
    end
  end
end
