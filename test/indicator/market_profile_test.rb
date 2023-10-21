# ./test/market_profile_test.rb


require_relative  '../test_helper'

class MarketProfileTest < Minitest::Test
  def test_market_profile
    result_mp   = SQA::Indicator.market_profile(
                    $data.close_prices,
                    $data.volume,
                    10.0, # support
                    13.0  # resistance
                  )

    expected_mp = :support

    assert_equal expected_mp, result_mp
  end
end


