# test/ensemble_test.rb
# frozen_string_literal: true

require_relative 'test_helper'
require 'ostruct'

class EnsembleTest < Minitest::Test
  def setup
    @strategies = [SQA::Strategy::RSI, SQA::Strategy::MACD, SQA::Strategy::SMA]
    @ensemble = SQA::Ensemble.new(strategies: @strategies, voting_method: :majority)

    # Create test vector
    @vector = OpenStruct.new(
      prices: Array.new(50) { rand(100..200) },
      close: 150.0,
      rsi: 45.0,
      macd: 2.0,
      macd_signal: 1.5,
      sma_20: 148.0,
      sma_50: 145.0
    )
  end

  def test_initialization
    assert_equal 3, @ensemble.strategies.size
    assert_equal 3, @ensemble.weights.size
    assert_in_delta 1.0, @ensemble.weights.sum, 0.01
  end

  def test_majority_vote
    signal = @ensemble.majority_vote(@vector)

    assert [:buy, :sell, :hold].include?(signal)
  end

  def test_weighted_vote
    signal = @ensemble.weighted_vote(@vector)

    assert [:buy, :sell, :hold].include?(signal)
  end

  def test_unanimous_vote
    signal = @ensemble.unanimous_vote(@vector)

    assert [:buy, :sell, :hold].include?(signal)
    # Most of the time should be :hold unless all agree
  end

  def test_confidence_vote
    # Set some confidence scores
    @ensemble.update_confidence(SQA::Strategy::RSI, true)
    @ensemble.update_confidence(SQA::Strategy::MACD, false)

    signal = @ensemble.confidence_vote(@vector)

    assert [:buy, :sell, :hold].include?(signal)
  end

  def test_update_weight
    initial_weights = @ensemble.weights.dup

    @ensemble.update_weight(0, 0.15)  # Good performance
    @ensemble.update_weight(1, -0.05)  # Bad performance

    # Weights should be different now
    refute_equal initial_weights, @ensemble.weights
  end

  def test_update_confidence
    initial_conf = @ensemble.instance_variable_get(:@confidence_scores)[SQA::Strategy::RSI]

    @ensemble.update_confidence(SQA::Strategy::RSI, true)
    new_conf = @ensemble.instance_variable_get(:@confidence_scores)[SQA::Strategy::RSI]

    assert new_conf > initial_conf, "Confidence should increase after correct prediction"
  end

  def test_statistics
    stats = @ensemble.statistics

    assert_instance_of Hash, stats
    assert stats.key?(:num_strategies)
    assert stats.key?(:weights)
    assert stats.key?(:confidence_scores)
    assert_equal 3, stats[:num_strategies]
  end

  def test_trade_method
    signal = @ensemble.trade(@vector)

    assert [:buy, :sell, :hold].include?(signal)
  end

  def test_different_voting_methods
    [:majority, :weighted, :unanimous, :confidence].each do |method|
      ensemble = SQA::Ensemble.new(strategies: @strategies, voting_method: method)
      signal = ensemble.signal(@vector)

      assert [:buy, :sell, :hold].include?(signal), "#{method} voting failed"
    end
  end

  def test_ensemble_with_custom_weights
    weights = [0.5, 0.3, 0.2]
    ensemble = SQA::Ensemble.new(
      strategies: @strategies,
      voting_method: :weighted,
      weights: weights
    )

    assert_equal weights, ensemble.weights
  end
end
