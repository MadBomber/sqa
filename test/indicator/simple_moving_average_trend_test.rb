# ./test/simple_moving_average_trend_test.rb


require_relative  '../test_helper'

class SimpleMovingAverageTrendTest < Minitest::Test
  def test_simple_moving_average_trend
    result_smat = SQA::Indicator.simple_moving_average_trend(
                    $data.volume,
                    $data.period
                  )

    expected_smat = {
      sma:    $data.expected_sma,
      trend:  :up,
      angle:  33.69
    }

    assert_equal expected_smat.class.name,  result_smat.class.name
    assert_equal expected_smat.keys.sort,   result_smat.keys.sort
    assert_equal expected_smat[:sma],       result_smat[:sma].map{|v| v.round(2)}
    assert_equal expected_smat[:angle],     result_smat[:angle].round(2)
  end
end


