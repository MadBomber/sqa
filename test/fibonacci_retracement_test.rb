# ./test/fibonacci_retracement_test.rb

require           'minitest/autorun'
require_relative  'test_helper'

class FibonacciRetracement_testTest < Minitest::Test
  def test_fibonacci_retracement
    result_fr   = SQA::Indicator.fibonacci_retracement(
                    15.0,   # swing_high -- price at top of peak
                    10.0    # swing_low  -- price at bottom of valley
                  ).map{|v| v.round(2)}

    expected_fr = [ 11.18, 11.91, 12.5, 13.09, 13.93]

    assert_equal expected_fr, result_fr
  end
end


