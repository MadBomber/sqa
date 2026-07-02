#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using FPL (Future Period Loss/Profit) Analysis
#
# This example demonstrates how to use the FPOP utilities to analyze
# potential future price movements and filter trading opportunities by
# risk and directional bias.

require 'sqa'

SQA.init

puts "=" * 70
puts "FPL (Future Period Loss/Profit) Analysis Example"
puts "=" * 70
puts

# Example 1: Basic FPL Calculation
puts "\n" + "=" * 70
puts "Example 1: Basic FPL Calculation"
puts "=" * 70
puts

# Simple price series
prices = [100, 102, 98, 105, 110, 115, 120, 118, 125, 130]

puts "Price series: #{prices.inspect}"
puts

# Calculate FPL with 3-day future period
fpl_data = SQA::FPOP.fpl(prices, fpop: 3)

puts "FPL Analysis (fpop=3):"
puts "-" * 70
fpl_data.each_with_index do |(min_delta, max_delta), idx|
  puts "Index #{idx} (Price: #{prices[idx]}): " \
       "Min: #{min_delta.round(2)}%, Max: #{max_delta.round(2)}%"
end
puts

# Example 2: Detailed FPL Analysis with Risk Metrics
puts "\n" + "=" * 70
puts "Example 2: Detailed FPL Analysis with Risk Metrics"
puts "=" * 70
puts

analysis = SQA::FPOP.fpl_analysis(prices, fpop: 3)

puts "Detailed Analysis:"
puts "-" * 70
analysis.each_with_index do |result, idx|
  puts "Index #{idx}: #{result[:interpretation]}"
  puts "  Direction: #{result[:direction]}"
  puts "  Magnitude: #{result[:magnitude].round(2)}%"
  puts "  Risk (Volatility): #{result[:risk].round(2)}%"
  puts "  Range: #{result[:min_delta].round(2)}% to #{result[:max_delta].round(2)}%"
  puts
end

# Example 3: Filtering by Quality
puts "\n" + "=" * 70
puts "Example 3: Filtering High-Quality Opportunities"
puts "=" * 70
puts

# Find low-risk, high-magnitude, bullish opportunities
quality_indices = SQA::FPOP.filter_by_quality(
  analysis,
  min_magnitude: 5.0,      # At least 5% average movement
  max_risk: 10.0,          # At most 10% volatility
  directions: [:UP]        # Only bullish movements
)

puts "High-quality bullish opportunities (magnitude ≥ 5%, risk ≤ 10%):"
puts "-" * 70
quality_indices.each do |idx|
  result = analysis[idx]
  puts "Index #{idx} (Price: #{prices[idx]}): #{result[:interpretation]}"
end
puts

# Example 4: Real Stock Data Analysis
puts "\n" + "=" * 70
puts "Example 4: Real Stock Data FPL Analysis"
puts "=" * 70
puts

if ENV['RUN_INTEGRATION_TESTS']
  # Load real stock data
  puts "Loading stock data for AAPL..."
  stock = SQA::Stock.new(ticker: 'AAPL')
  puts "Loaded #{stock.df.size} days of price history"
  puts

  # Use DataFrame convenience method
  stock_fpl_analysis = stock.df.fpl_analysis(fpop: 14)

  # Analyze recent data (last 10 points)
  puts "FPL Analysis for last 10 trading days (fpop=14):"
  puts "-" * 70
  stock_fpl_analysis.last(10).each_with_index do |result, idx|
    actual_idx = stock_fpl_analysis.size - 10 + idx
    puts "Day #{actual_idx}: #{result[:interpretation]}"
  end
  puts

  # Find all high-quality opportunities in entire history
  quality_indices = SQA::FPOP.filter_by_quality(
    stock_fpl_analysis,
    min_magnitude: 8.0,
    max_risk: 15.0,
    directions: [:UP, :DOWN]
  )

  puts "Found #{quality_indices.size} high-quality opportunities"
  puts "  (magnitude ≥ 8%, risk ≤ 15%, clear direction)"
  puts

  # Distribution of directions
  directions_dist = stock_fpl_analysis.map { |r| r[:direction] }.tally
  puts "Direction distribution across all #{stock_fpl_analysis.size} points:"
  directions_dist.each do |direction, count|
    pct = (count.to_f / stock_fpl_analysis.size * 100).round(2)
    puts "  #{direction}: #{count} (#{pct}%)"
  end
  puts

  # Risk-reward analysis
  ratios = SQA::FPOP.risk_reward_ratios(stock_fpl_analysis)
  avg_ratio = ratios.sum / ratios.size
  puts "Average risk-reward ratio: #{avg_ratio.round(3)}"
else
  puts "Skipping real stock analysis (set RUN_INTEGRATION_TESTS=1 to enable)"
end

# Example 5: Using FPL with Strategy Generator
puts "\n" + "=" * 70
puts "Example 5: FPL-Enhanced Strategy Generator"
puts "=" * 70
puts

if ENV['RUN_INTEGRATION_TESTS']
  puts "Generating strategies with FPL quality filtering..."
  puts

  # Create generator with FPL quality filters
  generator = SQA::StrategyGenerator.new(
    stock: stock,
    min_gain_percent: 10.0,
    fpop: 10,
    max_fpl_risk: 20.0,           # NEW: Filter high-volatility points
    required_fpl_directions: [:UP] # NEW: Only consider bullish patterns
  )

  patterns = generator.discover_patterns(min_pattern_frequency: 2)

  if patterns.any?
    puts "Discovered #{patterns.size} patterns from FPL-filtered opportunities"
    puts

    # Show quality metrics of discovered patterns
    profitable_points = generator.profitable_points
    if profitable_points.first.fpl_direction
      avg_risk = profitable_points.map(&:fpl_risk).compact.sum / profitable_points.size
      avg_magnitude = profitable_points.map(&:fpl_magnitude).compact.sum / profitable_points.size

      puts "FPL Quality Metrics of Discovered Patterns:"
      puts "  Average risk: #{avg_risk.round(2)}%"
      puts "  Average magnitude: #{avg_magnitude.round(2)}%"
      puts "  All patterns are #{generator.required_fpl_directions.inspect} direction"
    end
  else
    puts "No patterns found with current FPL filters"
    puts "Try relaxing max_fpl_risk or removing direction requirements"
  end
else
  puts "Skipping FPL-enhanced strategy generation (set RUN_INTEGRATION_TESTS=1)"
end

puts
puts "=" * 70
puts "FPL Analysis Complete!"
puts "=" * 70
puts
puts "Key Takeaways:"
puts "- FPL shows potential upside (max_delta) and downside (min_delta)"
puts "- Risk metric measures volatility during the future period"
puts "- Direction classification helps identify clear trends vs uncertain markets"
puts "- Use quality filters to find high-probability, low-risk opportunities"
puts "- Integrate with Strategy Generator for risk-aware pattern discovery"
