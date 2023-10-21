# test/true_range_test.rb


require_relative  '../test_helper'

class TrueRangeTest < Minitest::Test
  def test_true_range
    result_tr = SQA::Indicator.true_range(
                  $data.high_prices,
                  $data.low_prices,
                  $data.close_prices
                )

    assert_equal $data.expected_tr, result_tr
  end
end
