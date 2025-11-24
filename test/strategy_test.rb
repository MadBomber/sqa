# frozen_string_literal: true

require_relative 'test_helper'

class StrategyTest < Minitest::Test
  def setup
    @strategy = SQA::Strategy.new
  end

  def test_initialize_creates_empty_strategies_array
    assert_equal [], @strategy.strategies
  end

  def test_add_accepts_class_with_trade_method
    # Create a mock strategy class with a trade method
    mock_class = Class.new do
      def self.trade(v)
        :hold
      end
    end

    @strategy.add(mock_class)
    assert_equal 1, @strategy.strategies.size
  end

  def test_add_accepts_method_object
    # Create a method object
    mock_class = Class.new do
      def self.trade(v)
        :buy
      end
    end
    method_obj = mock_class.method(:trade)

    @strategy.add(method_obj)
    assert_equal 1, @strategy.strategies.size
  end

  def test_add_raises_for_invalid_type
    # Test that non-Class and non-Method objects raise BadParameterError
    assert_raises(SQA::BadParameterError) { @strategy.add("string") }
    assert_raises(SQA::BadParameterError) { @strategy.add(123) }
    assert_raises(SQA::BadParameterError) { @strategy.add([]) }
    assert_raises(SQA::BadParameterError) { @strategy.add({}) }
    assert_raises(SQA::BadParameterError) { @strategy.add(nil) }
  end

  def test_add_raises_for_proc
    # Procs are not Method objects, should raise
    a_proc = -> (v) { :hold }
    assert_raises(SQA::BadParameterError) { @strategy.add(a_proc) }
  end

  def test_add_raises_for_lambda
    # Lambdas are not Method objects, should raise
    a_lambda = lambda { |v| :hold }
    assert_raises(SQA::BadParameterError) { @strategy.add(a_lambda) }
  end

  def test_execute_returns_array_of_results
    mock_class = Class.new do
      def self.trade(v)
        :hold
      end
    end

    @strategy.add(mock_class)
    result = @strategy.execute(OpenStruct.new(price: 100))

    assert_kind_of Array, result
    assert_equal [:hold], result
  end

  def test_execute_with_multiple_strategies
    buy_class = Class.new do
      def self.trade(v)
        :buy
      end
    end

    sell_class = Class.new do
      def self.trade(v)
        :sell
      end
    end

    @strategy.add(buy_class)
    @strategy.add(sell_class)

    result = @strategy.execute(OpenStruct.new(price: 100))

    assert_equal [:buy, :sell], result
  end

  def test_available_returns_strategy_classes
    # available method finds classes under SQA::Strategy:: namespace
    available = @strategy.available

    assert_kind_of Array, available
    # Should include built-in strategies (check by name to avoid pretty_please gem conflict)
    assert available.any? { |klass| klass.name&.start_with?("SQA::Strategy::") }
  end

  def test_strategies_accessor
    assert_respond_to @strategy, :strategies
    assert_respond_to @strategy, :strategies=
  end
end
