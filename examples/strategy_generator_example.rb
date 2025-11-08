#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Strategy Generator - Reverse Engineering Profitable Trades
#
# This example demonstrates how to use SQA::StrategyGenerator to:
# 1. Identify historically profitable entry points
# 2. Discover which indicators were active at those points
# 3. Generate trading strategies from discovered patterns
# 4. Backtest the generated strategies

require 'sqa'

SQA.init

puts "=" * 70
puts "Strategy Generator: Mining Profitable Patterns"
puts "=" * 70
puts

# Load stock data
puts "Loading stock data for AAPL..."
stock = SQA::Stock.new(ticker: 'AAPL')
puts "Loaded #{stock.df.data.height} days of price history"
puts

# Example 1: Basic Pattern Discovery
puts "\n" + "=" * 70
puts "Example 1: Discovering Patterns for 10% Gains"
puts "=" * 70
puts

generator = SQA::StrategyGenerator.new(
  stock: stock,
  min_gain_percent: 10.0,     # Find trades that gained ≥10%
  holding_period: (5..20)     # Within 5-20 days
)

# Discover patterns
patterns = generator.discover_patterns(min_pattern_frequency: 3)

# Print discovered patterns
generator.print_patterns(max_patterns: 10)

# Example 2: Generate Strategies from Patterns
puts "\n" + "=" * 70
puts "Example 2: Generating Strategies from Top Patterns"
puts "=" * 70
puts

if patterns.any?
  # Generate top 3 strategies
  strategies = generator.generate_strategies(top_n: 3, strategy_type: :class)

  puts "Generated #{strategies.size} strategies from top patterns"
  puts

  # Test each generated strategy
  strategies.each_with_index do |strategy, i|
    puts "-" * 70
    puts "Testing Generated Strategy ##{i + 1}"
    puts "Pattern: #{strategy.pattern}"
    puts

    backtest = SQA::Backtest.new(
      stock: stock,
      strategy: strategy,
      initial_capital: 10_000.0,
      commission: 1.0
    )

    results = backtest.run

    puts "Backtest Results:"
    puts "  Total Return: #{results.total_return.round(2)}%"
    puts "  Sharpe Ratio: #{results.sharpe_ratio.round(2)}"
    puts "  Max Drawdown: #{results.max_drawdown.round(2)}%"
    puts "  Win Rate: #{results.win_rate.round(2)}%"
    puts "  Total Trades: #{results.total_trades}"
    puts
  end
end

# Example 3: Different Gain Thresholds
puts "\n" + "=" * 70
puts "Example 3: Comparing Different Gain Thresholds"
puts "=" * 70
puts

gain_thresholds = [5.0, 10.0, 15.0, 20.0]

gain_thresholds.each do |threshold|
  puts "-" * 70
  puts "Target Gain: #{threshold}%"
  puts

  gen = SQA::StrategyGenerator.new(
    stock: stock,
    min_gain_percent: threshold,
    holding_period: (5..20)
  )

  patterns = gen.discover_patterns(min_pattern_frequency: 2)

  if patterns.any?
    top_pattern = patterns.first
    puts "Top Pattern Found:"
    puts "  Frequency: #{top_pattern.frequency} occurrences"
    puts "  Average Gain: #{top_pattern.avg_gain.round(2)}%"
    puts "  Average Holding: #{top_pattern.avg_holding_days.round(1)} days"
    puts "  Conditions: #{top_pattern.conditions}"
  else
    puts "No patterns found for #{threshold}% gain threshold"
  end
  puts
end

# Example 4: Short vs Long Holding Periods
puts "\n" + "=" * 70
puts "Example 4: Short-term vs Long-term Patterns"
puts "=" * 70
puts

holding_configs = [
  { name: "Short-term", period: (3..10) },
  { name: "Medium-term", period: (10..30) },
  { name: "Long-term", period: (30..60) }
]

holding_configs.each do |config|
  puts "-" * 70
  puts "#{config[:name]} Trading (#{config[:period]} days)"
  puts

  gen = SQA::StrategyGenerator.new(
    stock: stock,
    min_gain_percent: 10.0,
    holding_period: config[:period]
  )

  patterns = gen.discover_patterns(min_pattern_frequency: 2)

  if patterns.any?
    puts "Discovered #{patterns.size} patterns"
    puts "Top Pattern:"
    top = patterns.first
    puts "  Frequency: #{top.frequency}"
    puts "  Avg Gain: #{top.avg_gain.round(2)}%"
    puts "  Avg Holding: #{top.avg_holding_days.round(1)} days"
    puts "  Conditions: #{top.conditions.keys.join(', ')}"
  else
    puts "No patterns found"
  end
  puts
end

# Example 5: Export Patterns to CSV
puts "\n" + "=" * 70
puts "Example 5: Exporting Patterns"
puts "=" * 70
puts

generator = SQA::StrategyGenerator.new(
  stock: stock,
  min_gain_percent: 10.0,
  holding_period: (5..20)
)

patterns = generator.discover_patterns(min_pattern_frequency: 2)

if patterns.any?
  output_file = "/tmp/sqa_discovered_patterns.csv"
  generator.export_patterns(output_file)
  puts "Patterns exported successfully!"
  puts "View with: cat #{output_file}"
  puts
end

# Example 6: Generate and Compare Multiple Strategies
puts "\n" + "=" * 70
puts "Example 6: Strategy Performance Comparison"
puts "=" * 70
puts

generator = SQA::StrategyGenerator.new(
  stock: stock,
  min_gain_percent: 10.0,
  holding_period: (5..20)
)

patterns = generator.discover_patterns(min_pattern_frequency: 3)

if patterns.size >= 3
  puts "Comparing Top 3 Discovered Strategies vs Traditional Strategies"
  puts "-" * 70
  puts

  comparison = []

  # Test discovered strategies
  [0, 1, 2].each do |i|
    strategy = generator.generate_strategy(pattern_index: i, strategy_type: :class)

    backtest = SQA::Backtest.new(
      stock: stock,
      strategy: strategy,
      initial_capital: 10_000.0,
      commission: 1.0
    )

    results = backtest.run

    comparison << {
      name: "Discovered ##{i + 1}",
      return: results.total_return,
      sharpe: results.sharpe_ratio,
      drawdown: results.max_drawdown,
      win_rate: results.win_rate,
      trades: results.total_trades
    }
  end

  # Test traditional strategies for comparison
  traditional_strategies = [
    { name: "RSI", class: SQA::Strategy::RSI },
    { name: "MACD", class: SQA::Strategy::MACD },
    { name: "Bollinger Bands", class: SQA::Strategy::BollingerBands }
  ]

  traditional_strategies.each do |strat|
    backtest = SQA::Backtest.new(
      stock: stock,
      strategy: strat[:class],
      initial_capital: 10_000.0,
      commission: 1.0
    )

    results = backtest.run

    comparison << {
      name: strat[:name],
      return: results.total_return,
      sharpe: results.sharpe_ratio,
      drawdown: results.max_drawdown,
      win_rate: results.win_rate,
      trades: results.total_trades
    }
  end

  # Print comparison table
  puts "Strategy Performance Comparison:"
  puts "-" * 70
  printf("%-20s %10s %10s %12s %10s %8s\n",
         "Strategy", "Return %", "Sharpe", "Drawdown %", "Win Rate", "Trades")
  puts "-" * 70

  comparison.sort_by { |s| -s[:return] }.each do |s|
    printf("%-20s %10.2f %10.2f %12.2f %9.1f%% %8d\n",
           s[:name],
           s[:return],
           s[:sharpe],
           s[:drawdown],
           s[:win_rate],
           s[:trades])
  end
  puts "-" * 70
  puts

  # Find best performer
  best = comparison.max_by { |s| s[:return] }
  puts "🏆 Best Performer: #{best[:name]}"
  puts "   Total Return: #{best[:return].round(2)}%"
  puts "   Sharpe Ratio: #{best[:sharpe].round(2)}"
  puts
end

# Example 7: Aggressive Pattern Mining
puts "\n" + "=" * 70
puts "Example 7: Aggressive Pattern Discovery (High Gains)"
puts "=" * 70
puts

aggressive_gen = SQA::StrategyGenerator.new(
  stock: stock,
  min_gain_percent: 20.0,  # Very high gain target
  holding_period: (5..30)
)

aggressive_patterns = aggressive_gen.discover_patterns(min_pattern_frequency: 1)

if aggressive_patterns.any?
  puts "Aggressive patterns found for 20%+ gains:"
  aggressive_gen.print_patterns(max_patterns: 5)

  # Test the most aggressive pattern
  puts "Testing Most Aggressive Pattern:"
  puts "-" * 70

  aggressive_strategy = aggressive_gen.generate_strategy(
    pattern_index: 0,
    strategy_type: :class
  )

  backtest = SQA::Backtest.new(
    stock: stock,
    strategy: aggressive_strategy,
    initial_capital: 10_000.0,
    commission: 1.0
  )

  results = backtest.run

  puts "Results:"
  puts "  Total Return: #{results.total_return.round(2)}%"
  puts "  Sharpe Ratio: #{results.sharpe_ratio.round(2)}"
  puts "  Max Drawdown: #{results.max_drawdown.round(2)}%"
  puts "  Win Rate: #{results.win_rate.round(2)}%"
  puts "  Total Trades: #{results.total_trades}"
  puts
  puts "⚠️  Note: High gain patterns often have lower frequency and higher risk"
else
  puts "No patterns found for 20%+ gains (criteria too strict)"
end
puts

puts "=" * 70
puts "Strategy Generation Complete!"
puts "=" * 70
puts
puts "Key Takeaways:"
puts "1. Pattern discovery identifies what indicators were active at profitable points"
puts "2. Higher gain thresholds yield fewer but potentially more profitable patterns"
puts "3. Different holding periods reveal different trading styles"
puts "4. Generated strategies can outperform traditional single-indicator strategies"
puts "5. Always backtest discovered patterns before live trading"
puts
puts "Next Steps:"
puts "- Combine with Genetic Programming to optimize pattern parameters"
puts "- Use KBS to create rule-based strategies from complex patterns"
puts "- Test on multiple stocks to find universal patterns"
puts "- Walk-forward validate patterns on out-of-sample data"
