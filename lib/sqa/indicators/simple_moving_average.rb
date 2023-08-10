# fin_tech/lib/fin_tech/simple_moving_average.rb

module FinTech

  #######################################################################
  # Simple Moving Average (SMA)
  #
  # This method takes in an array of historical prices for a stock and a
  # period (the number of days to calculate the moving average over). It
  # uses the `each_cons` method to iterate over a sliding window of closing
  # prices and calculate the moving average for each window. The method
  # returns an array of the moving averages for each window.

  def simple_moving_average(data, period)
    if data.first.is_a? Hash
      prices = data.map{|r| r['Adj Close'].to_f}
    else
      prices = data
    end

    moving_averages = []
    prices.each_cons(period) do |window|
      moving_average = window.sum / period.to_f
      moving_averages << moving_average
    end
    return moving_averages
  end
  alias_method :sma, :simple_moving_average


  # Simple Moving Average Trend - up or down with angle
  #
  def sma_trend(data, period)
    closes    = data.map{|r| r['Adj Close'].to_f}
    sma       = simple_moving_average(closes, period)
    last_sma  = sma.last
    prev_sma  = sma[-2]
    angle     = Math.atan((last_sma - prev_sma) / period) * (180 / Math::PI)

    if last_sma > prev_sma
      trend = 'up'
    else
      trend = 'down'
    end

    { trend: trend, angle: angle }
  end

end

