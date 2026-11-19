# frozen_string_literal: true

require_relative '../test_helper'
require 'ostruct'

class MPTest < Minitest::Test
  def test_buy_signal_at_support
    vector = OpenStruct.new(market_profile: :support)

    assert_equal :buy, SQA::Strategy::MP.trade(vector)
  end

  def test_sell_signal_at_resistance
    vector = OpenStruct.new(market_profile: :resistance)

    assert_equal :sell, SQA::Strategy::MP.trade(vector)
  end

  def test_hold_signal_when_mixed
    vector = OpenStruct.new(market_profile: :mixed)

    assert_equal :hold, SQA::Strategy::MP.trade(vector)
  end

  def test_responds_to_trade
    assert_respond_to SQA::Strategy::MP, :trade
  end

  def test_extends_common_module
    assert_respond_to SQA::Strategy::MP, :trade_against
    assert_respond_to SQA::Strategy::MP, :desc
  end
end
