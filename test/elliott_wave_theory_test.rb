# ./test/elliott_wave_theory_test.rb

require           'minitest/autorun'
require_relative  'test_helper'

class ElliottWaveTheoryTest < Minitest::Test
  def test_elliott_wave_theory
    prices = [10, 15, 16, 14, 12, 16, 20, 20, 18, 22, 25]

    result_ewt  = SQA::Indicator.elliott_wave_theory(
                    prices,
                  )

    expected_ewt = []

    assert_equal expected_ewt, result_ewt
  end
end


