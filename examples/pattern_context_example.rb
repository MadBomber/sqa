#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Context-Aware Pattern Discovery with KBS
#
# This example demonstrates the full Pattern Context system:
# 1. Market regime detection (bull/bear/sideways)
# 2. Seasonal pattern analysis (monthly/quarterly)
# 3. Sector analysis with KBS blackboards
# 4. Context-aware pattern discovery
# 5. Walk-forward validation to prevent overfitting
#
# Key Insight: Patterns aren't universal. They work in specific contexts:
# - Market regimes (bull vs bear)
# - Seasons (Q4 holiday shopping)
# - Sectors (tech stocks move together)
#
# This system helps identify WHEN and WHERE patterns are valid.

require 'sqa'

SQA.init

puts "=" * 80
puts "CONTEXT-AWARE PATTERN DISCOVERY SYSTEM"
puts "=" * 80
puts

# Only run integration tests if explicitly requested
if ENV['RUN_INTEGRATION_TESTS']

  # Example 1: Market Regime Detection
  puts "\n" + "=" * 80
  puts "Example 1: Market Regime Detection"
  puts "=" * 80
  puts

  stock = SQA::Stock.new(ticker: 'AAPL')
  puts "Loaded #{stock.df.size} days of AAPL history"
  puts

  # Detect current regime
  regime = SQA::MarketRegime.detect(stock)
  puts "Current Market Regime:"
  puts "  Type: #{regime[:type]}"
  puts "  Volatility: #{regime[:volatility]}"
  puts "  Strength: #{regime[:strength]}"
  puts

  # Analyze regime history
  regime_history = SQA::MarketRegime.detect_history(stock)
  puts "Regime History (#{regime_history.size} distinct periods):"
  regime_history.last(5).each do |r|
    puts "  #{r[:type].to_s.upcase.ljust(10)} - #{r[:duration]} days"
  end
  puts

  # Example 2: Seasonal Pattern Analysis
  puts "\n" + "=" * 80
  puts "Example 2: Seasonal Pattern Analysis"
  puts "=" * 80
  puts

  seasonal = SQA::SeasonalAnalyzer.analyze(stock)
  puts "Seasonal Performance:"
  puts "  Best performing months: #{seasonal[:best_months].map { |m| Date::MONTHNAMES[m] }.join(', ')}"
  puts "  Worst performing months: #{seasonal[:worst_months].map { |m| Date::MONTHNAMES[m] }.join(', ')}"
  puts "  Best quarters: Q#{seasonal[:best_quarters].join(', Q')}"
  puts "  Has seasonal pattern: #{seasonal[:has_seasonal_pattern] ? 'YES' : 'NO'}"
  puts

  # Show monthly returns
  puts "Monthly Average Returns:"
  seasonal[:monthly_returns].sort_by { |m, _| m }.each do |month, stats|
    month_name = Date::MONTHNAMES[month].ljust(10)
    avg_return = stats[:avg_return].round(2)
    sign = avg_return >= 0 ? '+' : ''
    puts "  #{month_name}: #{sign}#{avg_return}% (#{stats[:count]} samples)"
  end
  puts

  # Example 3: Sector Analysis with KBS Blackboards
  puts "\n" + "=" * 80
  puts "Example 3: Sector Analysis with KBS Blackboards"
  puts "=" * 80
  puts

  analyzer = SQA::SectorAnalyzer.new

  # Add technology stocks
  tech_stocks = ['AAPL', 'MSFT', 'GOOGL'].map { |t| SQA::Stock.new(ticker: t) }
  tech_stocks.each { |s| analyzer.add_stock(s, sector: :technology) }

  puts "Analyzing Technology sector (#{tech_stocks.size} stocks)"
  puts

  # Detect sector regime
  sector_regime = analyzer.detect_sector_regime(:technology, tech_stocks)
  puts "Technology Sector Regime:"
  puts "  Consensus: #{sector_regime[:consensus_regime]}"
  puts "  Sector strength: #{sector_regime[:sector_strength]}% bullish"
  puts

  # Discover sector-wide patterns
  puts "Discovering sector-wide patterns..."
  sector_patterns = analyzer.discover_sector_patterns(
    :technology,
    tech_stocks,
    min_gain_percent: 8.0,
    fpop: 10,
    max_fpl_risk: 20.0
  )

  if sector_patterns.any?
    puts "\nSector-Wide Patterns Found: #{sector_patterns.size}"
    sector_patterns.first(3).each_with_index do |sp, i|
      puts "\n  Pattern #{i + 1}:"
      puts "    Stocks: #{sp[:stocks].join(', ')}"
      puts "    Avg Frequency: #{sp[:avg_frequency].round(1)}"
      puts "    Avg Gain: #{sp[:avg_gain].round(2)}%"
      puts "    Conditions: #{sp[:conditions]}"
    end
  end
  puts

  # Print sector summary
  analyzer.print_sector_summary(:technology)

  # Example 4: Context-Aware Pattern Discovery
  puts "\n" + "=" * 80
  puts "Example 4: Context-Aware Pattern Discovery"
  puts "=" * 80
  puts

  generator = SQA::StrategyGenerator.new(
    stock: stock,
    min_gain_percent: 10.0,
    fpop: 10,
    max_fpl_risk: 20.0,
    required_fpl_directions: [:UP]
  )

  # Discover patterns with full context
  context_patterns = generator.discover_context_aware_patterns(
    analyze_regime: true,
    analyze_seasonal: true,
    sector: :technology
  )

  puts "\nDiscovered Context-Aware Patterns:"
  context_patterns.first(3).each_with_index do |pattern, i|
    puts "\n  Pattern #{i + 1}:"
    puts "    Frequency: #{pattern.frequency}"
    puts "    Avg Gain: #{pattern.avg_gain.round(2)}%"
    puts "    Context: #{pattern.context.summary}"
    puts "    Market Regime: #{pattern.context.market_regime}"
    puts "    Valid Months: #{pattern.context.valid_months.map { |m| Date::MONTHNAMES[m] }.join(', ')}" if pattern.context.valid_months.any?
    puts "    Sector: #{pattern.context.sector}"
    puts "    Conditions: #{pattern.conditions}"
  end
  puts

  # Example 5: Walk-Forward Validation
  puts "\n" + "=" * 80
  puts "Example 5: Walk-Forward Validation (Prevent Overfitting)"
  puts "=" * 80
  puts

  puts "Running time-series cross-validation..."
  puts "(This validates patterns on out-of-sample data)"
  puts

  validation_results = generator.walk_forward_validate(
    train_size: 250,  # 1 year training
    test_size: 60,    # ~3 months testing
    step_size: 30     # Step forward 1 month each iteration
  )

  validated_patterns = validation_results[:validated_patterns]
  all_results = validation_results[:validation_results]

  puts "\nValidation Summary:"
  puts "  Total patterns tested: #{all_results.size}"
  puts "  Patterns validated (positive return, Sharpe > 0.5): #{validated_patterns.size}"
  puts

  if all_results.any?
    # Calculate statistics
    returns = all_results.map { |r| r[:test_return] }
    sharpes = all_results.map { |r| r[:test_sharpe] }.compact
    drawdowns = all_results.map { |r| r[:test_max_drawdown] }.compact

    avg_return = returns.sum / returns.size
    avg_sharpe = sharpes.any? ? sharpes.sum / sharpes.size : 0
    avg_drawdown = drawdowns.any? ? drawdowns.sum / drawdowns.size : 0

    puts "Out-of-Sample Performance:"
    puts "  Avg Return: #{avg_return.round(2)}%"
    puts "  Avg Sharpe: #{avg_sharpe.round(2)}"
    puts "  Avg Max Drawdown: #{avg_drawdown.round(2)}%"
    puts

    # Show best validated patterns
    if validated_patterns.any?
      puts "Best Validated Patterns (worked out-of-sample):"
      validated_patterns.uniq.first(3).each_with_index do |pattern, i|
        puts "\n  Pattern #{i + 1}:"
        puts "    Frequency: #{pattern.frequency}"
        puts "    Avg Gain (in-sample): #{pattern.avg_gain.round(2)}%"
        puts "    Conditions: #{pattern.conditions}"
      end
    else
      puts "⚠️  No patterns passed validation!"
      puts "This suggests discovered patterns may be overfit to historical data."
      puts "Try:"
      puts "  - Adjusting thresholds"
      puts "  - Increasing min_pattern_frequency"
      puts "  - Using context filters (regime, seasonal)"
    end
  end
  puts

  # Example 6: Pattern Validity Checking
  puts "\n" + "=" * 80
  puts "Example 6: Runtime Pattern Validity Checking"
  puts "=" * 80
  puts

  if context_patterns.any?
    pattern = context_patterns.first

    puts "Checking if pattern is valid for different scenarios:"
    puts

    # Scenario 1: Current date in valid month
    test_date = Date.new(2024, 12, 15)  # December
    valid = pattern.context.valid_for?(
      date: test_date,
      regime: :bull,
      sector: :technology
    )
    puts "  December 15, 2024 (Bull market, Tech sector): #{valid ? '✓ VALID' : '✗ INVALID'}"

    # Scenario 2: Wrong month
    test_date = Date.new(2024, 6, 15)  # June
    valid = pattern.context.valid_for?(
      date: test_date,
      regime: :bull,
      sector: :technology
    )
    puts "  June 15, 2024 (Bull market, Tech sector): #{valid ? '✓ VALID' : '✗ INVALID'}"

    # Scenario 3: Wrong regime
    valid = pattern.context.valid_for?(
      date: Date.new(2024, 12, 15),
      regime: :bear,
      sector: :technology
    )
    puts "  December 15, 2024 (Bear market, Tech sector): #{valid ? '✓ VALID' : '✗ INVALID'}"

    # Scenario 4: Wrong sector
    valid = pattern.context.valid_for?(
      date: Date.new(2024, 12, 15),
      regime: :bull,
      sector: :finance
    )
    puts "  December 15, 2024 (Bull market, Finance sector): #{valid ? '✓ VALID' : '✗ INVALID'}"
  end
  puts

  puts "=" * 80
  puts "COMPLETE PATTERN CONTEXT SYSTEM DEMONSTRATION FINISHED"
  puts "=" * 80
  puts

  puts "Key Takeaways:"
  puts "  ✓ Patterns have context (regime, season, sector)"
  puts "  ✓ Market regimes change (bull/bear/sideways)"
  puts "  ✓ Seasonal patterns exist (best months/quarters)"
  puts "  ✓ Sector analysis finds patterns across related stocks"
  puts "  ✓ Walk-forward validation prevents overfitting"
  puts "  ✓ Runtime validation checks if pattern applies NOW"
  puts
  puts "This context-aware approach is much more sophisticated than"
  puts "naive pattern mining that assumes universal applicability."
  puts

else
  puts "Skipping integration tests (set RUN_INTEGRATION_TESTS=1 to enable)"
  puts
  puts "This example demonstrates:"
  puts "  1. Market Regime Detection - Identify bull/bear/sideways markets"
  puts "  2. Seasonal Analysis - Find which months/quarters patterns work"
  puts "  3. Sector Analysis - Discover patterns across related stocks using KBS"
  puts "  4. Context-Aware Discovery - Patterns with regime/seasonal metadata"
  puts "  5. Walk-Forward Validation - Prevent overfitting with time-series CV"
  puts "  6. Runtime Validity - Check if pattern applies in current conditions"
  puts
  puts "Run with: RUN_INTEGRATION_TESTS=1 ruby #{__FILE__}"
end
