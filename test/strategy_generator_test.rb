require_relative 'test_helper'

class StrategyGeneratorTest < Minitest::Test
  def setup
    skip "Requires network access for stock data" unless ENV['RUN_INTEGRATION_TESTS']

    SQA.init
    @stock = SQA::Stock.new(ticker: 'AAPL')
  end

  def test_initialization
    skip "Requires network access" unless ENV['RUN_INTEGRATION_TESTS']

    generator = SQA::StrategyGenerator.new(
      stock: @stock,
      min_gain_percent: 10.0,
      fpop: 10
    )

    assert_equal @stock, generator.stock
    assert_equal 10.0, generator.min_gain_percent
    assert_equal 10, generator.fpop
  end

  def test_profitable_point_creation
    point = SQA::StrategyGenerator::ProfitablePoint.new(
      entry_index: 10,
      entry_price: 100.0,
      exit_index: 15,
      exit_price: 115.0
    )

    assert_equal 10, point.entry_index
    assert_equal 100.0, point.entry_price
    assert_equal 115.0, point.exit_price
    assert_in_delta 15.0, point.gain_percent, 0.01
    assert_equal 5, point.holding_days
  end

  def test_pattern_creation
    pattern = SQA::StrategyGenerator::Pattern.new(
      conditions: { rsi: :oversold, macd: :bullish }
    )

    assert_equal 2, pattern.conditions.size
    assert_equal :oversold, pattern.conditions[:rsi]
    assert_equal 0, pattern.frequency
  end

  def test_discover_patterns
    skip "Requires network access" unless ENV['RUN_INTEGRATION_TESTS']
    skip "Long running test"

    generator = SQA::StrategyGenerator.new(
      stock: @stock,
      min_gain_percent: 10.0,
      fpop: 10
    )

    patterns = generator.discover_patterns(min_pattern_frequency: 2)

    assert_instance_of Array, patterns
    # May or may not find patterns depending on data
  end

  def test_generate_proc_strategy
    skip "Requires network access" unless ENV['RUN_INTEGRATION_TESTS']
    skip "Long running test"

    generator = SQA::StrategyGenerator.new(
      stock: @stock,
      min_gain_percent: 5.0,
      fpop: 10
    )

    patterns = generator.discover_patterns(min_pattern_frequency: 1)

    skip "No patterns found" if patterns.empty?

    strategy = generator.generate_strategy(pattern_index: 0, strategy_type: :proc)

    assert_instance_of Proc, strategy
  end

  def test_generate_class_strategy
    skip "Requires network access" unless ENV['RUN_INTEGRATION_TESTS']
    skip "Long running test"

    generator = SQA::StrategyGenerator.new(
      stock: @stock,
      min_gain_percent: 5.0,
      fpop: 10
    )

    patterns = generator.discover_patterns(min_pattern_frequency: 1)

    skip "No patterns found" if patterns.empty?

    strategy = generator.generate_strategy(pattern_index: 0, strategy_type: :class)

    assert_instance_of Class, strategy
    assert_respond_to strategy, :trade
  end

  def test_export_patterns
    skip "Requires network access" unless ENV['RUN_INTEGRATION_TESTS']
    skip "Long running test"

    generator = SQA::StrategyGenerator.new(
      stock: @stock,
      min_gain_percent: 5.0,
      fpop: 10
    )

    patterns = generator.discover_patterns(min_pattern_frequency: 1)

    skip "No patterns found" if patterns.empty?

    require 'tempfile'
    file = Tempfile.new(['patterns', '.csv'])

    generator.export_patterns(file.path)

    assert File.exist?(file.path)
    assert File.size(file.path) > 0

    file.close
    file.unlink
  end

  def test_indicators_config
    skip "Requires network access" unless ENV['RUN_INTEGRATION_TESTS']

    generator = SQA::StrategyGenerator.new(
      stock: @stock,
      min_gain_percent: 10.0
    )

    config = generator.indicators_config

    assert config.key?(:rsi)
    assert config.key?(:macd)
    assert config.key?(:stoch)
    assert config.key?(:sma_cross)
  end
end
