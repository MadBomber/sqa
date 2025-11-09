# frozen_string_literal: true

require_relative '../test_helper'
require 'ostruct'

class EMATest < Minitest::Test
  def test_buy_signal_when_trend_up
    ema_data = { trend: :up }
    vector = OpenStruct.new(ema: ema_data)
    signal = SQA::Strategy::EMA.trade(vector)

    assert_equal :buy, signal
  end

  def test_sell_signal_when_trend_down
    ema_data = { trend: :down }
    vector = OpenStruct.new(ema: ema_data)
    signal = SQA::Strategy::EMA.trade(vector)

    assert_equal :sell, signal
  end

  def test_hold_signal_when_neutral
    ema_data = { trend: :neutral }
    vector = OpenStruct.new(ema: ema_data)
    signal = SQA::Strategy::EMA.trade(vector)

    assert_equal :hold, signal
  end

  def test_responds_to_trade
    assert_respond_to SQA::Strategy::EMA, :trade
  end

  def test_extends_common_module
    assert_respond_to SQA::Strategy::EMA, :trade_against
    assert_respond_to SQA::Strategy::EMA, :desc
  end
end
