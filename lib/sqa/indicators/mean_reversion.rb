# lib/sqa/indicators/mean_reversion.rb

module SQA::Indicators

  #######################################################################
  # Determines if a stock exhibits mean reversion behavior based on a given
  # price series.
  #
  # Mean Reversion Strategies: Mean reversion strategies aim to capitalize on
  # the tendency of prices to revert to their mean or average value. These
  # strategies involve identifying overextended price movements and taking
  # positions that anticipate a return to the mean.
  #
  # @param prices [Array] An array of historical prices.
  # @param lookback_period [Integer] The number of periods to consider for calculating the mean.
  # @param deviation_threshold [Float]  The threshold for considering a
  #                                     price movement as overextended.  For example
  #                                     0.50 is a 50 cent (half dollar) change.
  # @return [Boolean] True if the stock exhibits mean reversion behavior,
  #                   false otherwise.
  #
  def mean_reversion?(prices, lookback_period, deviation_threshold)
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
    prices[-lookback_period..-1].sum / lookback_period.to_f
  end

end


