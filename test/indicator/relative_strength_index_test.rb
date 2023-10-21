# ./test/relative_strength_index_test.rb

require_relative  '../test_helper'

class RelativeStrengthIndexTest < Minitest::Test
  def test_relative_strength_index
    result_rsi  = SQA::Indicator.relative_strength_index(
                    $data.close_prices,
                    $data.period
                  )

    expected_rsi = {
      rsi:    87.5,
      trend:  :over_bought
    }

    assert_equal expected_rsi, result_rsi
  end
end


