#!/usr/bin/env ruby
# Diagnostic script to check CSV file ordering

require_relative 'lib/sqa'
SQA.init

ticker = ARGV[0] || 'AAPL'

puts "=" * 70
puts "CSV Data Order Diagnostic"
puts "=" * 70
puts "Ticker: #{ticker}"
puts "Data directory: #{SQA.data_dir}"
puts

begin
  stock = SQA::Stock.new(ticker: ticker)

  timestamps = stock.df["timestamp"].to_a
  prices = stock.df["adj_close_price"].to_a

  puts "Total data points: #{timestamps.size}"
  puts

  if timestamps.size >= 5
    puts "First 5 timestamps (should be oldest):"
    timestamps.first(5).each_with_index do |ts, i|
      puts "  [#{i}] #{ts} - $#{prices[i]}"
    end
    puts

    puts "Last 5 timestamps (should be newest):"
    timestamps.last(5).each_with_index do |ts, i|
      idx = timestamps.size - 5 + i
      puts "  [#{idx}] #{ts} - $#{prices[idx]}"
    end
    puts

    # Check order
    first_date = Date.parse(timestamps.first.to_s)
    last_date = Date.parse(timestamps.last.to_s)

    if first_date < last_date
      puts "✅ CSV is in ASCENDING order (oldest-first) - CORRECT for TA-Lib!"
    else
      puts "❌ CSV is in DESCENDING order (newest-first) - WRONG for TA-Lib!"
      puts "   This will cause indicator calculations to fail."
      puts
      puts "   FIX: Delete #{SQA.data_dir}/#{ticker.downcase}.csv and re-fetch"
      puts "   OR: Run your data cleaning script to reverse the order"
    end
    puts

    # Test RSI calculation
    puts "Testing RSI calculation..."
    rsi = SQAI.rsi(prices, period: 14)

    if rsi.nil? || rsi.empty?
      puts "❌ RSI returned no data"
    elsif rsi.compact.empty?
      puts "❌ RSI returned all NaN/nil values"
    elsif rsi.last.nil? || rsi.last.nan?
      puts "❌ Latest RSI is NaN/nil"
    else
      puts "✅ Latest RSI: #{rsi.last.round(2)}"

      # Show last 10 RSI values
      puts
      puts "Last 10 RSI values:"
      rsi.last(10).each_with_index do |val, i|
        idx = rsi.size - 10 + i
        status = val.nil? || val.nan? ? "❌ NaN" : "✅ #{val.round(2)}"
        puts "  [#{idx}] #{timestamps[idx]} - #{status}"
      end
    end

  else
    puts "Not enough data points to analyze (need at least 5)"
  end

rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
end

puts
puts "=" * 70
