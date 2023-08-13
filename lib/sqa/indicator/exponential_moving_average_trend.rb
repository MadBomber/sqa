# lib/sqa/indicator/exponential_moving_average_trend.rb

class SQA::Indicator; class << self

  def exponential_moving_average_trend(
        prices, # Array of prices
        period  # Integer number of entries to consider
      )

    ema_values  = exponential_moving_average(
                    prices,
                    period
                  )

    last_ema      = ema_values.last
    previous_ema  = ema_values[-2]

    trend = if last_ema > previous_ema
              :up
            elsif last_ema < previous_ema
              :down
            else
              :neutral
            end

    {
      ema:        ema_values,
      trend:      trend,
      support:    ema_values.min,
      resistance: ema_values.max
    }
  end
  alias_method :ema_trend, :exponential_moving_average_trend

end; end

