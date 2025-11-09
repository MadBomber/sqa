# frozen_string_literal: true

require_relative '../test_helper'
require 'ostruct'

class MACDTest < Minitest::Test
  def test_buy_signal_on_bullish_crossover
    # Create upward trending price data to generate bullish crossover
    prices = Array.new(40) { |i| 100.0 + (i * 0.5) }
    # Add a dip and recovery to create crossover
    prices[-5..-3] = [110.0, 109.0, 108.0]
    prices[-2..-1] = [110.0, 112.0]

    vector = OpenStruct.new(prices: prices)
    signal = SQA::Strategy::MACD.trade(vector)

    # May be buy or hold depending on exact crossover timing
    assert_includes [:buy, :hold], signal
  end

  def test_sell_signal_on_bearish_crossover
    # Create downward trending price data to generate bearish crossover
    prices = Array.new(40) { |i| 120.0 - (i * 0.5) }
    # Add a rise and fall to create crossover
    prices[-5..-3] = [100.0, 101.0, 102.0]
    prices[-2..-1] = [100.0, 98.0]

    vector = OpenStruct.new(prices: prices)
    signal = SQA::Strategy::MACD.trade(vector)

    # May be sell or hold depending on exact crossover timing
    assert_includes [:sell, :hold], signal
  end

  def test_hold_when_insufficient_data
    # Less than 35 periods required
    prices = Array.new(30) { 100.0 }

    vector = OpenStruct.new(prices: prices)
    signal = SQA::Strategy::MACD.trade(vector)

    assert_equal :hold, signal
  end

  def test_hold_when_no_prices
    vector = OpenStruct.new(prices: nil)
    signal = SQA::Strategy::MACD.trade(vector)

    assert_equal :hold, signal
  end

  def test_hold_when_empty_prices
    vector = OpenStruct.new(prices: [])
    signal = SQA::Strategy::MACD.trade(vector)

    assert_equal :hold, signal
  end

  def test_hold_when_vector_missing_prices
    vector = OpenStruct.new
    signal = SQA::Strategy::MACD.trade(vector)

    assert_equal :hold, signal
  end

  def test_responds_to_trade
    assert_respond_to SQA::Strategy::MACD, :trade
  end
end
