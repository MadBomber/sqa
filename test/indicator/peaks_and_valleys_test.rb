# ./test/peaks_and_valleys_test.rb


require_relative  '../test_helper'

class PeaksAndValleysTest < Minitest::Test
  def test_peaks_and_valleys
    result_pav  = SQA::Indicator.peaks_and_valleys(
                    $data.close_prices,
                    1
                  )

    expected_pav = {
      period:   3,
      peaks:    [14.0, 20.0],
      valleys:  [13.0]
    }

    assert_equal expected_pav, result_pav
  end
end


