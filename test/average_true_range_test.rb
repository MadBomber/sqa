# test/average_true_range_test.rb

require           'minitest/autorun'
require_relative  'test_helper'

class AverageTrueRangeTest < Minitest::Test
  def test_average_true_range
    result_atr  = SQA::Indicator.average_true_range(
                    $data.high_prices,
                    $data.low_prices,
                    $data.close_prices,
                    $data.period
                  ).map{|v| v.round(2)}

    assert_equal $data.expected_atr, result_atr
  end
end


