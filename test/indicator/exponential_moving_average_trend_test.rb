# ./test/exponential_moving_average_trend_test.rb.rb


require_relative  '../test_helper'

class ExponentialMovingAverageTrendTest < Minitest::Test
  def test_exponential_moving_average_trend
    result_emat = SQA::Indicator.exponential_moving_average_trend(
                    $data.volume,
                    $data.period
                  )

    expected_emat = {
      ema:        $data.expected_ema,
      trend:      :up,
      support:    0.0,
      resistance: 8.0
    }

    assert_equal expected_emat.class.name,    result_emat.class.name
    assert_equal expected_emat.keys.sort,     result_emat.keys.sort
    assert_equal expected_emat[:ema],         result_emat[:ema].map{|v| v.round(2)}
    assert_equal expected_emat[:trend],       result_emat[:trend]
    assert_equal expected_emat[:support],     result_emat[:support].round(2)
    assert_equal expected_emat[:resistance],  result_emat[:resistance].round(2)
  end
end


