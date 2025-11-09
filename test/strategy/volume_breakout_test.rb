# frozen_string_literal: true

require_relative '../test_helper'
require 'ostruct'

class VolumeBreakoutTest < Minitest::Test
  def test_buy_signal_on_price_breakout_with_high_volume
    # Create stable price then breakout
    prices = Array.new(20) { 100.0 }
    prices[-2] = 100.0  # at resistance
    prices[-1] = 105.0  # breakout above

    volumes = Array.new(20) { 1000.0 }
    volumes[-1] = 2000.0  # High volume (2x average)

    vector = OpenStruct.new(prices: prices, volumes: volumes)
    signal = SQA::Strategy::VolumeBreakout.trade(vector)

    assert_equal :buy, signal
  end

  def test_sell_signal_on_price_breakdown_with_high_volume
    # Create stable price then breakdown
    prices = Array.new(20) { 100.0 }
    prices[-2] = 100.0  # at support
    prices[-1] = 95.0   # breakdown below

    volumes = Array.new(20) { 1000.0 }
    volumes[-1] = 2000.0  # High volume (2x average)

    vector = OpenStruct.new(prices: prices, volumes: volumes)
    signal = SQA::Strategy::VolumeBreakout.trade(vector)

    assert_equal :sell, signal
  end

  def test_hold_when_insufficient_price_data
    prices = Array.new(15) { 100.0 }
    volumes = Array.new(20) { 1000.0 }

    vector = OpenStruct.new(prices: prices, volumes: volumes)
    signal = SQA::Strategy::VolumeBreakout.trade(vector)

    assert_equal :hold, signal
  end

  def test_hold_when_insufficient_volume_data
    prices = Array.new(20) { 100.0 }
    volumes = Array.new(15) { 1000.0 }

    vector = OpenStruct.new(prices: prices, volumes: volumes)
    signal = SQA::Strategy::VolumeBreakout.trade(vector)

    assert_equal :hold, signal
  end

  def test_hold_when_no_volumes
    prices = Array.new(20) { 100.0 }
    vector = OpenStruct.new(prices: prices, volumes: nil)
    signal = SQA::Strategy::VolumeBreakout.trade(vector)

    assert_equal :hold, signal
  end

  def test_hold_when_low_volume
    # Breakout but insufficient volume
    prices = Array.new(20) { 100.0 }
    prices[-1] = 105.0

    volumes = Array.new(20) { 1000.0 }
    volumes[-1] = 1100.0  # Only slightly above average

    vector = OpenStruct.new(prices: prices, volumes: volumes)
    signal = SQA::Strategy::VolumeBreakout.trade(vector)

    assert_equal :hold, signal
  end

  def test_responds_to_trade
    assert_respond_to SQA::Strategy::VolumeBreakout, :trade
  end
end
