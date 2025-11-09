# frozen_string_literal: true

require_relative '../test_helper'
require 'ostruct'

class StochasticTest < Minitest::Test
  def test_hold_when_insufficient_data
    prices = Array.new(10) { 100.0 }
    vector = OpenStruct.new(prices: prices)
    signal = SQA::Strategy::Stochastic.trade(vector)

    assert_equal :hold, signal
  end

  def test_hold_when_no_prices
    vector = OpenStruct.new(prices: nil)
    signal = SQA::Strategy::Stochastic.trade(vector)

    assert_equal :hold, signal
  end

  def test_hold_when_empty_prices
    vector = OpenStruct.new(prices: [])
    signal = SQA::Strategy::Stochastic.trade(vector)

    assert_equal :hold, signal
  end

  def test_hold_when_vector_missing_prices
    vector = OpenStruct.new
    signal = SQA::Strategy::Stochastic.trade(vector)

    assert_equal :hold, signal
  end

  def test_returns_valid_signal_with_sufficient_data
    # Create price data with enough periods
    prices = Array.new(30) { |i| 100.0 + (i * 0.5) }

    vector = OpenStruct.new(prices: prices)
    signal = SQA::Strategy::Stochastic.trade(vector)

    assert_includes [:buy, :sell, :hold], signal
  end

  def test_responds_to_trade
    assert_respond_to SQA::Strategy::Stochastic, :trade
  end
end
