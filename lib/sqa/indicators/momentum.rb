# lib/sqa/indicators/momentum.rb

module SQA::Indicators

  # @param prices [Array] An array of historical prices.
  # @param period [Integer] The number of periods to consider for calculating the ROC.
  # @return [Float] The momentum of the stock.
  #
  def momentum(prices, period)
    return 0.0 if prices.length <= period

    current_price = prices[-1]
    past_price = prices[-(period + 1)]

    roc = (current_price - past_price) / past_price.to_f
    momentum = roc * 100.0

    momentum
  end

end

