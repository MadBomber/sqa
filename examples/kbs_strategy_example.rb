#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using Knowledge-Based Strategy with RETE Forward Chaining
#
# This example shows how to use SQA::Strategy::KBS to create
# sophisticated rule-based trading systems.

require 'sqa'

SQA.init

puts "=" * 60
puts "Knowledge-Based Strategy (RETE) Example"
puts "=" * 60
puts

# Load stock data
puts "Loading stock data for AAPL..."
stock = SQA::Stock.new(ticker: 'AAPL')
puts "Loaded #{stock.df.data.height} days of price history"
puts

# Example 1: Using Default Rules
puts "\n" + "=" * 60
puts "Example 1: KBS with Default Rules"
puts "=" * 60
puts

strategy = SQA::Strategy::KBS.new(load_defaults: true)

puts "Loaded rules:"
strategy.print_rules
puts

# Prepare data vector
prices = stock.df["adj_close_price"].to_a
volumes = stock.df["volume"].to_a
highs = stock.df["high_price"].to_a
lows = stock.df["low_price"].to_a

require 'ostruct'
vector = OpenStruct.new(
  prices: prices,
  volumes: volumes,
  highs: highs,
  lows: lows,
  rsi: SQAI.rsi(prices, period: 14),
  macd: SQAI.macd(prices),
  stoch_k: SQAI.stoch(highs, lows, prices).first,
  stoch_d: SQAI.stoch(highs, lows, prices).last,
  bb_upper: SQAI.bbands(prices).first,
  bb_middle: SQAI.bbands(prices)[1],
  bb_lower: SQAI.bbands(prices)[2]
)

signal = strategy.execute(vector)
puts "Generated Signal: #{signal.upcase}"
puts

# Show what facts were asserted
puts "Market Facts Asserted:"
strategy.print_facts
puts

# Example 2: Custom Rules
puts "\n" + "=" * 60
puts "Example 2: KBS with Custom Rules"
puts "=" * 60
puts

custom_strategy = SQA::Strategy::KBS.new(load_defaults: false)

# Add custom rule: Aggressive buy on multiple confirmations
custom_strategy.add_rule :aggressive_buy do
  on :rsi, { level: :oversold }
  on :stochastic, { zone: :oversold }
  on :bollinger, { position: :below }
  send(:then) do
    assert(:signal, {
      action: :buy,
      confidence: :high,
      reason: :triple_confirmation
    })
  end
end

# Add custom rule: Conservative sell
custom_strategy.add_rule :conservative_sell do
  on :rsi, { level: :overbought }
  on :trend, { short_term: :down }
  send(:then) do
    assert(:signal, {
      action: :sell,
      confidence: :medium,
      reason: :overbought_downtrend
    })
  end
end

# Add custom rule: Volume-confirmed breakout
custom_strategy.add_rule :volume_breakout do
  on :trend, { short_term: :up, strength: :strong }
  on :volume, { level: :high }
  send(:then) do
    assert(:signal, {
      action: :buy,
      confidence: :high,
      reason: :volume_breakout
    })
  end
end

puts "Custom rules defined:"
custom_strategy.print_rules
puts

signal = custom_strategy.execute(vector)
puts "Generated Signal: #{signal.upcase}"
puts

# Example 3: Backtesting KBS Strategy
puts "\n" + "=" * 60
puts "Example 3: Backtesting KBS Strategy"
puts "=" * 60
puts

backtest = SQA::Backtest.new(
  stock: stock,
  strategy: SQA::Strategy::KBS,
  initial_capital: 10_000.0,
  commission: 1.0
)

results = backtest.run

puts "Backtest Results:"
puts "-" * 60
puts "Total Return: #{results.total_return.round(2)}%"
puts "Annualized Return: #{results.annualized_return.round(2)}%"
puts "Sharpe Ratio: #{results.sharpe_ratio.round(2)}"
puts "Max Drawdown: #{results.max_drawdown.round(2)}%"
puts "Total Trades: #{results.total_trades}"
puts "Win Rate: #{results.win_rate.round(2)}%"
puts "Profit Factor: #{results.profit_factor.round(2)}"
puts

# Example 4: Interactive Rule Building
puts "\n" + "=" * 60
puts "Example 4: Interactive Rule Builder"
puts "=" * 60
puts

interactive_strategy = SQA::Strategy::KBS.new(load_defaults: false)

# Build complex multi-condition rules
interactive_strategy.add_rule :golden_opportunity do
  desc "Perfect storm: Multiple bullish indicators align"

  # Multiple conditions
  on :rsi, { level: :oversold }
  on :macd, { crossover: :bullish }
  on :stochastic, { zone: :oversold, crossover: :bullish }
  on :trend, { short_term: :up, strength: :strong }
  on :volume, { level: :high }

  # Negation: Don't buy if already overbought elsewhere
  without :rsi, { level: :overbought }

  # Action
  send(:then) do
    assert(:signal, {
      action: :buy,
      confidence: :high,
      reason: :golden_opportunity,
      strength: 10
    })
    puts "  🎯 Golden opportunity detected!"
  end
end

interactive_strategy.add_rule :disaster_warning do
  desc "Red flags: Multiple bearish indicators"

  on :rsi, { level: :overbought }
  on :macd, { crossover: :bearish }
  on :trend, { short_term: :down }

  send(:then) do
    assert(:signal, {
      action: :sell,
      confidence: :high,
      reason: :disaster_warning,
      urgency: :high
    })
    puts "  ⚠️  Disaster warning detected!"
  end
end

puts "Interactive rules defined:"
interactive_strategy.print_rules
puts

signal = interactive_strategy.execute(vector)
puts "Final Signal: #{signal.upcase}"
puts

puts "Example complete!"
