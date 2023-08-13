# test/average_true_range_test.rb

require 'minitest/autorun'
require '../lib/sqa'

class AverageTrueRangeTest < Minitest::Test
  def test_average_true_range
    period        = 3
    high_prices   = [10.0, 12.0, 15.0, 14.0, 18.0, 21.0, 20.0]
    low_prices    = [ 8.0, 11.0, 13.0, 12.0, 16.0, 19.0, 18.0]
    close_prices  = [ 9.0, 11.0, 14.0, 13.0, 17.0, 20.0, 19.0]

    expected_tr   = [       3.0,  4.0,  2.0,  5.0,  4.0,  2.0]
    expected_atr  = [       3.0,  3.5,  3.0,  3.67, 3.67, 3.67]


    result_tr     = SQA::Indicator.true_range(
                      high_prices,
                      low_prices,
                      close_prices
                    ).map{|v| v.round(2)}

    result_atr    = SQA::Indicator.average_true_range(
                    high_prices,
                    low_prices,
                    close_prices,
                    period
                  ).map{|v| v.round(2)}

    assert_equal expected_tr,  result_tr
    assert_equal expected_atr, result_atr
  end
end


