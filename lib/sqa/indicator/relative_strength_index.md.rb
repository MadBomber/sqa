# lib/sqa/indicator/relative_strength_index.rb

class SQA::Indicator; class << self

  def relative_strength_index(
        prices,             # Array of prices
        period,             # Integer how many to consider at a time
        over_sold   = 30.0, # Float break over point in trend
        over_boufht = 70.0  # Float break over point in trend
      )
    gains   = []
    losses  = []

    prices.each_cons(2) do |pair|
      change = pair[1] - pair[0]

      if change > 0
        gains   << change
        losses  << 0
      else
        gains   << 0
        losses  << change.abs
      end
    end

    avg_gain  = gains.last(period).sum  / period.to_f
    avg_loss  = losses.last(period).sum / period.to_f
    rs        = avg_gain / avg_loss
    rsi       = 100 - (100 / (1 + rs))

    trend = if rsi >= over_bought
              :over_bought
            elsif rsi <= over_sold
              :over_sold
            else
              :normal
            end

    {
      rsi:    rsi,  # Float
      trend:  trend # Symbol :normal, :over_bought, :over+sold
    }
  end
  alias_method :rsi, :relative_strength_index

end; end

