# ./test/momentum_test.rb

require           'minitest/autorun'
require_relative  '../test_helper'

class MomentumTest < Minitest::Test
  def test_momentum
    result_m    = SQA::Indicator.momentum(
                    $data.close_prices,
                    $data.period
                  ).map{|v| v.round(2)}

    expected_m = [5.56, 1.82, 2.14, 5.38, 1.18]

    assert_equal expected_m, result_m
  end
end


