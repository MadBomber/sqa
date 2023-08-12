# test/true_range_test.rb

require 'minitest/autorun'
require_relative '../lib/sqa'

class TrueRangeTest < Minitest::Test
  def test_true_range
    high_prices     = [10, 12, 15, 18]
    low_prices      = [ 8, 11, 13, 16]
    closing_prices  = [ 9, 10, 14, 17]
    # h - l             2   1   2   3
    # h - pc            -   3   5   4
    # l - pc            -   2   3   2
    # max               -   3   5   4

    expected_true_ranges = [3,  5,  4]

    assert_equal expected_true_ranges, SQA::Indicator.true_range(high_prices, low_prices, closing_prices)
  end

  def test_tr_alias
    high_prices     = [10, 12, 15, 18]
    low_prices      = [ 8, 11, 13, 16]
    closing_prices  = [ 9, 10, 14, 17]

    expected_true_ranges = [3, 5, 4]

    assert_equal expected_true_ranges, SQA::Indicator.tr(high_prices, low_prices, closing_prices)
  end
end
