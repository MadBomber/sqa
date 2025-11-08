#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Real-Time Stock Price Streaming
#
# This example shows how to use SQA::Stream to process live stock
# price updates and generate trading signals in real-time.

require 'sqa'

SQA.init

puts "=" * 60
puts "Real-Time Stock Price Streaming Example"
puts "=" * 60
puts

# Example 1: Basic Streaming with Single Strategy
puts "\n" + "=" * 60
puts "Example 1: Basic Streaming Setup"
puts "=" * 60
puts

stream = SQA::Stream.new(
  ticker: 'AAPL',
  window_size: 100,
  strategies: [SQA::Strategy::RSI]
)

puts "Stream initialized:"
puts "  Ticker: #{stream.ticker}"
puts "  Window Size: #{stream.window_size}"
puts "  Strategies: #{stream.strategies.size}"
puts

# Add signal callback
stream.on_signal do |signal, data|
  puts "🔔 SIGNAL: #{signal.upcase}"
  puts "   Price: $#{data[:price].round(2)}"
  puts "   Time: #{data[:timestamp]}"
  puts "   Strategy Votes: #{data[:strategies_vote]}"
  puts
end

# Add update callback (optional - for monitoring)
update_count = 0
stream.on_update do |data|
  update_count += 1
  if update_count % 10 == 0
    puts "📊 Update ##{update_count}: Price=$#{data[:price].round(2)}"
  end
end

puts "Callbacks registered. Simulating price updates..."
puts "-" * 60

# Simulate real-time price updates
# In production, these would come from a WebSocket or API
stock = SQA::Stock.new(ticker: 'AAPL')
prices = stock.df["adj_close_price"].to_a
volumes = stock.df["volume"].to_a
highs = stock.df["high_price"].to_a
lows = stock.df["low_price"].to_a

# Stream the last 150 data points as if they were real-time
prices.last(150).each_with_index do |price, i|
  stream.update(
    price: price,
    volume: volumes.last(150)[i],
    high: highs.last(150)[i],
    low: lows.last(150)[i],
    timestamp: Time.now - (150 - i) * 60 # 1-minute intervals
  )

  # Simulate delay (in production, this happens naturally)
  # sleep(0.01) # Uncomment for slower demo
end

puts "-" * 60
puts "Streaming complete. Final statistics:"
stats = stream.stats
puts "  Total Updates: #{stats[:updates]}"
puts "  Current Price: $#{stats[:current_price].round(2)}"
puts "  Price Range: $#{stats[:price_range][:min].round(2)} - $#{stats[:price_range][:max].round(2)}"
puts "  Last Signal: #{stats[:last_signal].upcase}"
puts

# Example 2: Multi-Strategy Streaming
puts "\n" + "=" * 60
puts "Example 2: Multi-Strategy Consensus"
puts "=" * 60
puts

multi_stream = SQA::Stream.new(
  ticker: 'MSFT',
  window_size: 100,
  strategies: [
    SQA::Strategy::RSI,
    SQA::Strategy::MACD,
    SQA::Strategy::BollingerBands,
    SQA::Strategy::Stochastic
  ]
)

puts "Multi-strategy stream configured with:"
multi_stream.strategies.each_with_index do |strategy, i|
  puts "  #{i + 1}. #{strategy}"
end
puts

signal_log = []

multi_stream.on_signal do |signal, data|
  signal_log << { signal: signal, price: data[:price], votes: data[:strategies_vote] }
  puts "🎯 CONSENSUS SIGNAL: #{signal.upcase}"
  puts "   Price: $#{data[:price].round(2)}"
  puts "   Strategy Votes: #{data[:strategies_vote]}"
  puts "   Time: #{data[:timestamp].strftime('%Y-%m-%d %H:%M:%S')}"
  puts
end

puts "Simulating market data stream..."
puts "-" * 60

# Simulate streaming
stock2 = SQA::Stock.new(ticker: 'MSFT')
prices2 = stock2.df["adj_close_price"].to_a
volumes2 = stock2.df["volume"].to_a

prices2.last(100).each_with_index do |price, i|
  multi_stream.update(
    price: price,
    volume: volumes2.last(100)[i],
    timestamp: Time.now - (100 - i) * 60
  )
end

puts "-" * 60
puts "Multi-strategy streaming complete."
puts "Signal summary:"
signal_log.each_with_index do |log, i|
  puts "  #{i + 1}. #{log[:signal].to_s.upcase} at $#{log[:price].round(2)} (votes: #{log[:votes]})"
end
puts

# Example 3: Custom Indicator Access
puts "\n" + "=" * 60
puts "Example 3: Accessing Real-Time Indicators"
puts "=" * 60
puts

indicator_stream = SQA::Stream.new(
  ticker: 'GOOGL',
  window_size: 50
)

# Stream some data first
stock3 = SQA::Stock.new(ticker: 'GOOGL')
stock3.df["adj_close_price"].to_a.last(50).each do |price|
  indicator_stream.update(price: price)
end

puts "Current market data:"
puts "  Current Price: $#{indicator_stream.current_price.round(2)}"
puts "  Recent Prices (last 5): #{indicator_stream.recent_prices(5).map { |p| p.round(2) }}"
puts

puts "Real-time indicators:"
rsi = indicator_stream.indicator(:rsi, period: 14)
sma_20 = indicator_stream.indicator(:sma, period: 20)
ema_12 = indicator_stream.indicator(:ema, period: 12)
macd_data = indicator_stream.indicator(:macd)

puts "  RSI(14): #{rsi.last.round(2)}"
puts "  SMA(20): $#{sma_20.last.round(2)}"
puts "  EMA(12): $#{ema_12.last.round(2)}"
puts "  MACD: #{macd_data[0].last.round(4)}"
puts "  Signal: #{macd_data[1].last.round(4)}"
puts

# Example 4: Production-Style WebSocket Simulation
puts "\n" + "=" * 60
puts "Example 4: Production WebSocket Pattern"
puts "=" * 60
puts

class MockWebSocket
  def initialize(ticker)
    @ticker = ticker
    @stock = SQA::Stock.new(ticker: ticker)
    @prices = @stock.df["adj_close_price"].to_a
    @index = @prices.size - 100
  end

  def on_message(&block)
    @message_handler = block
  end

  def start
    puts "📡 WebSocket connected to #{@ticker} market data feed"
    puts "   Streaming live prices..."
    puts

    # Simulate receiving messages
    (@index...@prices.size).each do |i|
      # Simulate WebSocket message
      message = {
        symbol: @ticker,
        price: @prices[i],
        volume: rand(1_000_000..10_000_000),
        timestamp: Time.now
      }

      @message_handler.call(message) if @message_handler

      # sleep(0.1) # Uncomment for slower demo
    end

    puts "   WebSocket closed"
  end
end

# Initialize stream for production pattern
production_stream = SQA::Stream.new(
  ticker: 'TSLA',
  window_size: 100,
  strategies: [
    SQA::Strategy::RSI,
    SQA::Strategy::MACD,
    SQA::Strategy::BollingerBands
  ]
)

# Set up signal handling
production_stream.on_signal do |signal, data|
  # In production, this would trigger:
  # - Alert notifications
  # - Automated trading execution
  # - Logging to database
  # - Risk management checks

  puts "⚡ TRADING SIGNAL: #{signal.upcase}"
  puts "   Execute #{signal} order for #{data[:price]}"
  puts "   Consensus: #{data[:strategies_vote]}"
  puts
end

# Set up WebSocket (mock)
ws = MockWebSocket.new('TSLA')

ws.on_message do |message|
  # Feed WebSocket data into stream processor
  production_stream.update(
    price: message[:price],
    volume: message[:volume],
    timestamp: message[:timestamp]
  )
end

# Start streaming
ws.start

puts "-" * 60
puts "Production simulation complete."
puts

puts "All streaming examples complete!"
puts
puts "In production, connect to real WebSocket feeds from:"
puts "  - Alpha Vantage WebSocket API"
puts "  - Yahoo Finance Streaming"
puts "  - Interactive Brokers TWS API"
puts "  - Polygon.io WebSocket"
puts "  - Alpaca Markets WebSocket"
