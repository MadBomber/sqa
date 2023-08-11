# lib/sqa/indicators/simple_moving_average_trend.rb

module SQA::Indicators

  def simple_moving_average_trend(data, period)
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
  alias_method :sma_trend, :simple_moving_average_trend

end

