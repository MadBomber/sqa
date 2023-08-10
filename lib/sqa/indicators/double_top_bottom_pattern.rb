# lib/sqa/indicators/double_top_bottom_pattern.rb

module SQA::Indicators

  # Checks if a "double top" or "double bottom" pattern is present in the
  # given price data.
  #
  # @param prices [Array] An array of price values.
  # @return [String]  The pattern ("double top", "double bottom") if present,
  #                   "no pattern" otherwise.
  #
  def double_top_bottom_pattern?(prices)
    return "no pattern" if prices.length < 5

    first_peak = prices[0]
    valley = prices[1]
    second_peak = prices[2]
    neckline = prices[3]
    confirmation_price = prices[4]

    if first_peak < second_peak && valley > first_peak && valley > second_peak && confirmation_price < neckline
      return "double top"
    elsif first_peak > second_peak && valley < first_peak && valley < second_peak && confirmation_price > neckline
      return "double bottom"
    else
      return "no pattern"
    end
  end

end

