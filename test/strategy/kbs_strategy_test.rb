# frozen_string_literal: true

require_relative '../test_helper'
require 'ostruct'

class KBSStrategyTest < Minitest::Test
  def test_initializes_with_default_rules
    strategy = SQA::Strategy::KBS.new(load_defaults: true)

    assert strategy.default_rules_loaded
    refute_nil strategy.kb
  end

  def test_initializes_without_default_rules
    strategy = SQA::Strategy::KBS.new(load_defaults: false)

    refute strategy.default_rules_loaded
    refute_nil strategy.kb
  end

  def test_class_method_trade
    vector = OpenStruct.new(rsi: [50.0])
    signal = SQA::Strategy::KBS.trade(vector)

    assert_includes [:buy, :sell, :hold], signal
  end

  def test_execute_returns_valid_signal
    strategy = SQA::Strategy::KBS.new(load_defaults: false)
    vector = OpenStruct.new(rsi: [50.0])
    signal = strategy.execute(vector)

    assert_includes [:buy, :sell, :hold], signal
  end

  def test_add_rule_returns_self
    strategy = SQA::Strategy::KBS.new(load_defaults: false)

    result = strategy.add_rule(:test_rule) do
      on :rsi, { level: :oversold }
      perform { }  # Empty perform block for testing
    end

    assert_equal strategy, result
  end

  def test_custom_rule_can_be_executed
    # Test that custom rules can be added and executed without error
    # The default rules already test that signals work correctly
    strategy = SQA::Strategy::KBS.new(load_defaults: true)

    # Add a custom rule that doesn't conflict with defaults
    strategy.add_rule(:custom_test_rule) do
      on :rsi, { level: :neutral }
      perform { }  # Empty perform block for testing
    end

    # RSI value of 50 is neutral
    vector = OpenStruct.new(rsi: [50.0])
    signal = strategy.execute(vector)

    # Should return a valid signal (default behavior is :hold for neutral)
    assert_includes [:buy, :sell, :hold], signal
  end

  def test_default_rules_handle_oversold
    # Test that the default rules correctly handle oversold RSI with uptrend
    strategy = SQA::Strategy::KBS.new(load_defaults: true)

    # Provide both RSI and trend data (uptrend)
    prices = Array.new(50) { |i| 100.0 + i }  # Uptrend
    vector = OpenStruct.new(rsi: [25.0], prices: prices)

    signal = strategy.execute(vector)

    # With oversold RSI in uptrend, default rules should signal buy
    assert_equal :buy, signal
  end

  def test_assert_fact_works
    strategy = SQA::Strategy::KBS.new(load_defaults: false)

    # assert_fact should not raise an error and should return a fact
    result = strategy.assert_fact(:test, { value: 42 })
    # The KBS gem returns a Fact object, not nil
    refute_nil result
  end

  def test_query_facts_works
    strategy = SQA::Strategy::KBS.new(load_defaults: false)
    strategy.assert_fact(:test, { value: 42 })

    results = strategy.query_facts(:test, {})
    assert_kind_of Array, results
  end

  def test_handles_rsi_facts
    strategy = SQA::Strategy::KBS.new(load_defaults: false)
    vector = OpenStruct.new(rsi: [50.0])

    signal = strategy.execute(vector)
    assert_includes [:buy, :sell, :hold], signal
  end

  def test_handles_macd_facts
    strategy = SQA::Strategy::KBS.new(load_defaults: false)
    macd_line = [0.5, 0.6, 0.7]
    signal_line = [0.4, 0.5, 0.6]
    histogram = [0.1, 0.1, 0.1]

    vector = OpenStruct.new(macd: [macd_line, signal_line, histogram])

    signal = strategy.execute(vector)
    assert_includes [:buy, :sell, :hold], signal
  end

  def test_handles_price_trend_facts
    strategy = SQA::Strategy::KBS.new(load_defaults: false)
    prices = Array.new(50) { |i| 100.0 + i }

    vector = OpenStruct.new(prices: prices)

    signal = strategy.execute(vector)
    assert_includes [:buy, :sell, :hold], signal
  end

  def test_handles_volume_facts
    strategy = SQA::Strategy::KBS.new(load_defaults: false)
    volumes = Array.new(30) { 1000 }

    vector = OpenStruct.new(volume: volumes)

    signal = strategy.execute(vector)
    assert_includes [:buy, :sell, :hold], signal
  end

  def test_handles_empty_vector
    strategy = SQA::Strategy::KBS.new(load_defaults: false)
    vector = OpenStruct.new

    signal = strategy.execute(vector)
    assert_equal :hold, signal
  end

  def test_multiple_rules_can_be_added
    strategy = SQA::Strategy::KBS.new(load_defaults: false)

    strategy.add_rule(:rule1) do
      on :rsi, { level: :oversold }
      perform { }  # Empty perform block for testing
    end

    strategy.add_rule(:rule2) do
      on :rsi, { level: :overbought }
      perform { }  # Empty perform block for testing
    end

    # Should not raise error
    vector = OpenStruct.new(rsi: [50.0])
    signal = strategy.execute(vector)

    assert_includes [:buy, :sell, :hold], signal
  end

  def test_responds_to_print_facts
    strategy = SQA::Strategy::KBS.new(load_defaults: false)
    assert_respond_to strategy, :print_facts
  end

  def test_responds_to_print_rules
    strategy = SQA::Strategy::KBS.new(load_defaults: false)
    assert_respond_to strategy, :print_rules
  end

  def test_kb_accessor
    strategy = SQA::Strategy::KBS.new
    assert_respond_to strategy, :kb
    refute_nil strategy.kb
  end

  def test_default_rules_loaded_accessor
    strategy = SQA::Strategy::KBS.new
    assert_respond_to strategy, :default_rules_loaded
  end
end
