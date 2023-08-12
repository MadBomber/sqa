# lib/sqa/indicator/simple_moving_average_trend.rb

module SQA::Indicator; class << self

  def simple_moving_average_trend(
        closing_prices,   # Array of closing prices
        period,           # Integer number of entries to consider
        delta = 0.0005    # Float defines a :nutria trend range.
      )
    sma       = simple_moving_average(closing_prices, period)
    last_sma  = sma.last
    prev_sma  = sma[-2]
    angle     = Math.atan((last_sma - prev_sma) / period) * (180 / Math::PI)

    if angle > 0.0
      trend = :up
    elsif angle < 0.0
      trend = :down
    else
      trend = :neutral
    end

    {
      trend: trend, # Symbol :up, :down, :neutral
      angle: angle  # Float how step the trend
    }
  end
  alias_method :sma_trend, :simple_moving_average_trend

end; end

