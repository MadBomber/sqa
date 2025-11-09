# frozen_string_literal: true

require_relative '../test_helper'
require 'ostruct'

class MRTest < Minitest::Test
  def test_sell_signal_when_mr_true
    vector = OpenStruct.new(mr: true)
    signal = SQA::Strategy::MR.trade(vector)

    assert_equal :sell, signal
  end

  def test_hold_signal_when_mr_false
    vector = OpenStruct.new(mr: false)
    signal = SQA::Strategy::MR.trade(vector)

    assert_equal :hold, signal
  end

  def test_hold_signal_when_mr_nil
    vector = OpenStruct.new(mr: nil)
    signal = SQA::Strategy::MR.trade(vector)

    assert_equal :hold, signal
  end

  def test_responds_to_trade
    assert_respond_to SQA::Strategy::MR, :trade
  end

  def test_extends_common_module
    assert_respond_to SQA::Strategy::MR, :trade_against
    assert_respond_to SQA::Strategy::MR, :desc
  end
end
