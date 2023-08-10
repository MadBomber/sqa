# lib/sqa/indicators/rsi.rb

module SQA::Indicators

  #######################################################################
  # Relative Strength Index (RSI)
  #
  # This method takes in an array of historical prices for a stock and a
  # period (the number of days to calculate the RSI over). It uses
  # the `each_cons` method to iterate over a sliding window of closing
  # prices and calculate the gains and losses for each window. Then, it
  # calculates the average gain and average loss for the time period and
  # uses these values to calculate the RSI. The method returns the RSI
  # value for the given period.
  #
  #   over_bought if rsi >= 70
  #   over_sold   if rsi <= 30

  def rsi(data, period)
    prices  = data.map{|r| r['Adj Close'].to_f}
    gains   = []
    losses  = []

    prices.each_cons(2) do |pair|
      change = pair[1] - pair[0]
      if change > 0
        gains   << change
        losses  << 0
      else
        gains   << 0
        losses  << -change
      end
    end

    avg_gain  = gains.first(period).sum / period.to_f
    avg_loss  = losses.first(period).sum / period.to_f
    rs        = avg_gain / avg_loss
    rsi       = 100 - (100 / (1 + rs))

    meaning = ""
    if rsi >= 70.0
      meaning = "Over Bought"
    elsif rsi <= 30.0
      meaning = "Over Sold"
    end

    return {rsi: rsi, meaning: meaning}
  end

end

