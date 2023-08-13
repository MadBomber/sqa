# lib/sqa/indicator/simple_moving_average_trend.rb

class SQA::Indicator; class << self

  def simple_moving_average_trend(
        prices,           # Array of prices
        period,           # Integer number of entries to consider
        delta = 1.0       # Float defines the angle range(+/-) for :neutral trend
      )
    sma       = simple_moving_average(prices, period)
    last_sma  = sma.last
    prev_sma  = sma.last(period).first
    angle     = Math.atan((last_sma - prev_sma) / period) * (180 / Math::PI)

    trend = if angle > delta
              :up
            elsif angle < -delta
              :down
            else
              :neutral
            end

    {
      sma:    sma,    # Array
      trend:  trend,  # Symbol :up, :down, :neutral
      angle:  angle   # Float how step the trend
    }
  end
  alias_method :sma_trend, :simple_moving_average_trend

end; end

