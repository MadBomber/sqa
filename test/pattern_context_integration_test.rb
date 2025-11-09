# test/pattern_context_integration_test.rb
# frozen_string_literal: true

require_relative 'test_helper'

class PatternContextIntegrationTest < Minitest::Test
  def setup
    skip "Requires network access and integration tests" unless ENV['RUN_INTEGRATION_TESTS']

    @stock = SQA::Stock.new(ticker: 'AAPL')
  end

  def test_full_context_aware_workflow
    skip "Long running integration test" unless ENV['RUN_INTEGRATION_TESTS']

    # Step 1: Market Regime Detection
    regime = SQA::MarketRegime.detect(@stock)

    assert regime.is_a?(Hash)
    assert_includes [:bull, :bear, :sideways], regime[:type]
    puts "  ✓ Regime detected: #{regime[:type]}"

    # Step 2: Seasonal Analysis
    seasonal = SQA::SeasonalAnalyzer.analyze(@stock)

    assert seasonal.is_a?(Hash)
    assert seasonal[:best_months].size == 3
    assert seasonal[:best_quarters].size == 2
    puts "  ✓ Seasonal analysis complete"
    puts "    Best months: #{seasonal[:best_months]}"
    puts "    Best quarters: Q#{seasonal[:best_quarters].join(', Q')}"

    # Step 3: Context-Aware Pattern Discovery
    generator = SQA::StrategyGenerator.new(
      stock: @stock,
      min_gain_percent: 8.0,
      fpop: 10,
      max_fpl_risk: 25.0
    )

    patterns = generator.discover_context_aware_patterns(
      analyze_regime: true,
      analyze_seasonal: true,
      sector: :technology
    )

    assert patterns.is_a?(Array)
    puts "  ✓ Discovered #{patterns.size} context-aware patterns"

    # Verify patterns have context
    if patterns.any?
      pattern = patterns.first
      assert pattern.context.is_a?(SQA::StrategyGenerator::PatternContext)
      assert pattern.context.valid?

      puts "  ✓ Pattern context:"
      puts "    Regime: #{pattern.context.market_regime}"
      puts "    Volatility: #{pattern.context.volatility_regime}"
      puts "    Sector: #{pattern.context.sector}"
      puts "    Valid months: #{pattern.context.valid_months}" if pattern.context.valid_months.any?
    end

    # Step 4: Runtime Validation
    if patterns.any?
      pattern = patterns.first
      valid_now = pattern.context.valid_for?(
        date: Date.today,
        regime: regime[:type],
        sector: :technology
      )

      puts "  ✓ Pattern valid for today: #{valid_now}"
    end
  end

  def test_sector_analysis_integration
    skip "Requires multiple stocks" unless ENV['RUN_INTEGRATION_TESTS']

    analyzer = SQA::SectorAnalyzer.new

    # Add technology stocks
    tech_tickers = ['AAPL', 'MSFT']
    tech_stocks = tech_tickers.map { |t| SQA::Stock.new(ticker: t) }

    tech_stocks.each do |stock|
      analyzer.add_stock(stock.ticker, sector: :technology)
    end

    puts "  ✓ Added #{tech_stocks.size} tech stocks to sector analyzer"

    # Detect sector regime
    regime = analyzer.detect_sector_regime(:technology, tech_stocks)

    assert regime.is_a?(Hash)
    assert_includes [:bull, :bear, :sideways], regime[:consensus_regime]
    assert regime[:sector_strength] >= 0
    assert regime[:sector_strength] <= 100

    puts "  ✓ Sector regime: #{regime[:consensus_regime]} (#{regime[:sector_strength]}% bullish)"

    # Discover sector patterns
    patterns = analyzer.discover_sector_patterns(
      :technology,
      tech_stocks,
      min_gain_percent: 8.0,
      fpop: 10,
      max_fpl_risk: 25.0
    )

    assert patterns.is_a?(Array)
    puts "  ✓ Discovered #{patterns.size} sector-wide patterns"

    # Verify sector patterns
    if patterns.any?
      pattern = patterns.first
      assert pattern[:stocks].is_a?(Array)
      assert pattern[:stocks].size >= 2
      puts "    Pattern found in: #{pattern[:stocks].join(', ')}"
    end
  end

  def test_walk_forward_validation_integration
    skip "Very long running test" unless ENV['RUN_INTEGRATION_TESTS']

    generator = SQA::StrategyGenerator.new(
      stock: @stock,
      min_gain_percent: 8.0,
      fpop: 10
    )

    results = generator.walk_forward_validate(
      train_size: 120,
      test_size: 30,
      step_size: 30
    )

    assert results.is_a?(Hash)
    assert results.key?(:validated_patterns)
    assert results.key?(:validation_results)
    assert results.key?(:total_iterations)

    puts "  ✓ Walk-forward validation complete"
    puts "    Iterations: #{results[:total_iterations]}"
    puts "    Patterns tested: #{results[:validation_results].size}"
    puts "    Patterns validated: #{results[:validated_patterns].size}"

    # Check validation results structure
    if results[:validation_results].any?
      result = results[:validation_results].first
      assert result.key?(:iteration)
      assert result.key?(:pattern)
      assert result.key?(:train_period)
      assert result.key?(:test_period)
      assert result.key?(:test_return)
      assert result.key?(:test_sharpe)
      assert result.key?(:test_max_drawdown)
    end
  end

  def test_regime_history_and_splits
    skip "Requires stock object" unless ENV['RUN_INTEGRATION_TESTS']

    # Get regime history
    regimes = SQA::MarketRegime.detect_history(@stock, window: 60)

    assert regimes.is_a?(Array)
    assert regimes.size > 0
    puts "  ✓ Detected #{regimes.size} regime periods"

    # Verify structure
    regimes.each do |regime|
      assert_includes [:bull, :bear, :sideways], regime[:type]
      assert regime[:start_index] < regime[:end_index]
      assert regime[:duration] > 0
    end

    # Split by regime
    splits = SQA::MarketRegime.split_by_regime(@stock)

    assert splits.is_a?(Hash)
    assert_includes splits.keys, :bull
    assert_includes splits.keys, :bear
    assert_includes splits.keys, :sideways

    bull_days = splits[:bull].sum { |p| p[:duration] }
    bear_days = splits[:bear].sum { |p| p[:duration] }
    sideways_days = splits[:sideways].sum { |p| p[:duration] }

    puts "  ✓ Regime distribution:"
    puts "    Bull: #{bull_days} days"
    puts "    Bear: #{bear_days} days"
    puts "    Sideways: #{sideways_days} days"
  end

  def test_seasonal_filtering
    skip "Requires stock object" unless ENV['RUN_INTEGRATION_TESTS']

    # Filter for Q4 only
    q4_data = SQA::SeasonalAnalyzer.filter_by_quarters(@stock, [4])

    assert q4_data.is_a?(Hash)
    assert q4_data[:dates].size > 0
    puts "  ✓ Q4 data points: #{q4_data[:dates].size}"

    # Verify all dates are in Q4
    q4_data[:dates].each do |date|
      quarter = ((date.month - 1) / 3) + 1
      assert_equal 4, quarter
    end

    # Filter for specific months
    dec_data = SQA::SeasonalAnalyzer.filter_by_months(@stock, [12])

    assert dec_data.is_a?(Hash)
    assert dec_data[:dates].size > 0
    puts "  ✓ December data points: #{dec_data[:dates].size}"

    # Verify all dates are in December
    dec_data[:dates].each do |date|
      assert_equal 12, date.month
    end
  end

  def test_pattern_context_valid_for_scenarios
    skip "Requires stock object" unless ENV['RUN_INTEGRATION_TESTS']

    generator = SQA::StrategyGenerator.new(
      stock: @stock,
      min_gain_percent: 8.0,
      fpop: 10
    )

    patterns = generator.discover_context_aware_patterns(
      analyze_regime: true,
      analyze_seasonal: true,
      sector: :technology
    )

    if patterns.any?
      pattern = patterns.first

      # Test various scenarios
      scenarios = [
        { date: Date.new(2024, 12, 15), regime: :bull, sector: :technology },
        { date: Date.new(2024, 6, 15), regime: :bull, sector: :technology },
        { date: Date.new(2024, 12, 15), regime: :bear, sector: :technology },
        { date: Date.new(2024, 12, 15), regime: :bull, sector: :finance }
      ]

      puts "  ✓ Testing pattern validity for different scenarios:"
      scenarios.each do |scenario|
        valid = pattern.context.valid_for?(**scenario)
        month = Date::MONTHNAMES[scenario[:date].month] if scenario[:date]
        puts "    #{month} #{scenario[:regime]} #{scenario[:sector]}: #{valid ? '✓' : '✗'}"
      end
    end
  end
end
