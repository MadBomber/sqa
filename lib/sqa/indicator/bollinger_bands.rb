# lib/sqa/indicator/bollinger_bands.rb

class SQA::Indicator; class << self

  def bollinger_bands(
        prices,         # Array of prices
        period,         # Integer number of entries to consider
        num_std_devs=2  # Integer number of standard deviations
      )
    moving_averages     = simple_moving_average(prices, period)
    standard_deviations = []

    prices.each_cons(period) do |window|
      standard_deviation = Math.sqrt(window.map { |price| (price - moving_averages.last) ** 2 }.sum / period)
      standard_deviations << standard_deviation
    end

    upper_band = moving_averages.last + (num_std_devs * standard_deviations.last)
    lower_band = moving_averages.last - (num_std_devs * standard_deviations.last)

    {
      upper_band: upper_band, # Array
      lower_band: lower_band  # Array
    }
  end
  alias_method :bb, :bollinger_bands

end; end
