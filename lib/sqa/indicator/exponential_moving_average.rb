# lib/sqa/indicator/exponential_moving_average.rb

class SQA::Indicator; class << self

  def exponential_moving_average(
        prices, # Array of prices
        period  # Integer number of entries to consider
      )

    ema_values = []
    ema_values << prices.first

    multiplier = (2.0 / (period + 1))

    (1...prices.length).each do |x|
      ema = (prices[x] - ema_values.last) * multiplier + ema_values.last
      ema_values << ema
    end

    ema_values
  end
  alias_method :ema, :exponential_moving_average

end; end

