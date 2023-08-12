# lib/sqa/indicator/mean_reversion.rb

module SQA::Indicator; class << self

  # @param prices [Array]
  # @param lookback_period [Integer]
  # @param deviation_threshold [Float]
  #
  # @return [Boolean] True if the stock exhibits mean reversion behavior,
  #                   false otherwise.
  #
  def mean_reversion?(
        prices,             # Array of prices
        lookback_period,    # Integer number of events to consider
        deviation_threshold # Float delta change at which a price is considered to be over extended
      )

    return false if prices.length < lookback_period

    mean      = mr_mean(prices, lookback_period)
    deviation = prices[-1] - mean

    if deviation.abs > deviation_threshold
      return true
    else
      return false
    end
  end


  def mr_mean(prices, lookback_period)
    prices.last(lookback_period).sum / lookback_period.to_f
  end

end; end


