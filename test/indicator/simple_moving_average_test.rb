# ./test/simple_moving_average_test.rb

require_relative  '../test_helper'

class SimpleMovingAverageTest < Minitest::Test
  def test_simple_moving_average
    result_sma  = SQA::Indicator.simple_moving_average(
                    $data.volume,
                    $data.period
                  ).map{|v| v.round(2)}

    assert_equal $data.expected_sma, result_sma
  end
end


