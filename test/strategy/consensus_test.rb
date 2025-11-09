# frozen_string_literal: true

require_relative '../test_helper'
require 'ostruct'

class ConsensusTest < Minitest::Test
  def test_returns_buy_sell_or_hold
    vector = OpenStruct.new
    signal = SQA::Strategy::Consensus.trade(vector)

    assert_includes [:buy, :sell, :hold], signal
  end

  def test_uses_consensus_from_multiple_strategies
    # Run multiple times to test randomness
    signals = 10.times.map do
      SQA::Strategy::Consensus.trade(OpenStruct.new)
    end

    # Should have at least some variety due to randomness
    assert signals.uniq.size > 1, "Expected variety in signals due to random strategies"
  end

  def test_responds_to_trade
    assert_respond_to SQA::Strategy::Consensus, :trade
  end

  def test_extends_common_module
    assert_respond_to SQA::Strategy::Consensus, :trade_against
    assert_respond_to SQA::Strategy::Consensus, :desc
  end

  def test_instance_has_consensus_method
    instance = SQA::Strategy::Consensus.new(OpenStruct.new)
    assert_respond_to instance, :consensus
  end

  def test_instance_has_my_fancy_trader_method
    instance = SQA::Strategy::Consensus.new(OpenStruct.new)
    assert_respond_to instance, :my_fancy_trader
  end
end
