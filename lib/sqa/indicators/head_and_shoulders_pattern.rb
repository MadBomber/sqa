# lib/sqa/indicators/head_and_shoulders_pattern.rb

module SQA::Indicators

  # @param prices [Array] An array of price values.
  # @return [Boolean] True if the pattern is present, false otherwise.
  #
  def head_and_shoulders_pattern?(prices)
    return false if prices.length < 5

    left_shoulder = prices[0]
    head = prices[1]
    right_shoulder = prices[2]
    neckline = prices[3]
    right_peak = prices[4]

    if head > left_shoulder && head > right_shoulder && right_peak < neckline
      return true
    else
      return false
    end
  end

end
