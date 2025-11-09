# frozen_string_literal: true

require_relative '../test_helper'
require 'ostruct'

class BollingerBandsTest < Minitest::Test
  def test_buy_signal_when_price_at_lower_band
    # Create price data that will touch lower band
    prices = Array.new(30) { 100.0 }
    prices[-1] = 85.0  # Current price significantly below average

    vector = OpenStruct.new(prices: prices)
    signal = SQA::Strategy::BollingerBands.trade(vector)

    assert_equal :buy, signal
  end

  def test_sell_signal_when_price_at_upper_band
    # Create price data that will touch upper band
    prices = Array.new(30) { 100.0 }
    prices[-1] = 115.0  # Current price significantly above average

    vector = OpenStruct.new(prices: prices)
    signal = SQA::Strategy::BollingerBands.trade(vector)

    assert_equal :sell, signal
  end

  def test_hold_signal_when_price_between_bands
    # Create stable price data
    prices = Array.new(30) { 100.0 }

    vector = OpenStruct.new(prices: prices)
    signal = SQA::Strategy::BollingerBands.trade(vector)

    assert_equal :hold, signal
  end

  def test_hold_when_insufficient_data
    # Less than 20 periods
    prices = Array.new(15) { 100.0 }

    vector = OpenStruct.new(prices: prices)
    signal = SQA::Strategy::BollingerBands.trade(vector)

    assert_equal :hold, signal
  end

  def test_hold_when_no_prices
    vector = OpenStruct.new(prices: nil)
    signal = SQA::Strategy::BollingerBands.trade(vector)

    assert_equal :hold, signal
  end

  def test_hold_when_empty_prices
    vector = OpenStruct.new(prices: [])
    signal = SQA::Strategy::BollingerBands.trade(vector)

    assert_equal :hold, signal
  end

  def test_hold_when_vector_missing_prices
    vector = OpenStruct.new
    signal = SQA::Strategy::BollingerBands.trade(vector)

    assert_equal :hold, signal
  end

  def test_responds_to_trade
    assert_respond_to SQA::Strategy::BollingerBands, :trade
  end
end
