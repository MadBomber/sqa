# ./test/exponential_moving_average_test.rb.rb


require_relative  '../test_helper'

class ExponentialMovingAverageTest < Minitest::Test
  def test_exponential_moving_average
    result_ema  = SQA::Indicator.exponential_moving_average(
                    $data.volume,
                    $data.period
                  ).map{|v| v.round(2)}

    assert_equal $data.expected_ema, result_ema
  end
end


