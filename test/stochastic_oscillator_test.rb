# ./test/stochastic_oscillator_test.rb

require           'minitest/autorun'
require_relative  'test_helper'

class StochasticOscillatorTest < Minitest::Test
  # def test_stochastic_oscillator
  #   result_so   = SQA::Indicator.stochastic_oscillator(
  #                   $data.high_prices,
  #                   $data.low_prices,
  #                   $data.close_prices,
  #                   $data.period,
  #                   2 * $data.period
  #                 )
  #
  #   expected_so = []
  #
  #   assert_equal expected_so, result_so
  # end


  def test_stochastic_oscillator2
    result_so2  = SQA::Indicator.stochastic_oscillator2(
                    $data.close_prices,
                    $data.period
                  )

    expected_so2 = {
      k: [100.0,  66.67, 100.0,  100.0,   66.67],
      d: [                88.89,  88.89,  88.89]
    }

    assert_equal expected_so2[:k], result_so2[:k].map{|v| v.round(2)}
    assert_equal expected_so2[:d], result_so2[:d].map{|v| v.round(2)}
  end
end


