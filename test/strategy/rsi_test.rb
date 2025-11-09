# frozen_string_literal: true

require_relative '../test_helper'
require 'ostruct'

class RSITest < Minitest::Test
  def test_buy_signal_when_oversold
    rsi_data = { trend: :over_sold }
    vector = OpenStruct.new(rsi: rsi_data)
    signal = SQA::Strategy::RSI.trade(vector)

    assert_equal :buy, signal
  end

  def test_sell_signal_when_overbought
    rsi_data = { trend: :over_bought }
    vector = OpenStruct.new(rsi: rsi_data)
    signal = SQA::Strategy::RSI.trade(vector)

    assert_equal :sell, signal
  end

  def test_hold_signal_when_neutral
    rsi_data = { trend: :neutral }
    vector = OpenStruct.new(rsi: rsi_data)
    signal = SQA::Strategy::RSI.trade(vector)

    assert_equal :hold, signal
  end

  def test_responds_to_trade
    assert_respond_to SQA::Strategy::RSI, :trade
  end

  def test_extends_common_module
    assert_respond_to SQA::Strategy::RSI, :trade_against
    assert_respond_to SQA::Strategy::RSI, :desc
  end

  def test_trade_against_inverts_buy
    rsi_data = { trend: :over_sold }
    vector = OpenStruct.new(rsi: rsi_data)
    signal = SQA::Strategy::RSI.trade_against(vector)

    assert_equal :sell, signal
  end

  def test_trade_against_inverts_sell
    rsi_data = { trend: :over_bought }
    vector = OpenStruct.new(rsi: rsi_data)
    signal = SQA::Strategy::RSI.trade_against(vector)

    assert_equal :buy, signal
  end
end
