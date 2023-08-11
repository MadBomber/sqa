# lib/sqa/indicators/bollinger_bands.rb

module SQA::Indicators

  def bollinger_bands(data, period, num_std_devs=2)
    prices              = data.map{|r| r['Adj Close'].to_f}
    moving_averages     = simple_moving_average(data, period)
    standard_deviations = []

    prices.each_cons(period) do |window|
      standard_deviation = Math.sqrt(window.map { |price| (price - moving_averages.last) ** 2 }.sum / period)
      standard_deviations << standard_deviation
    end

    upper_band = moving_averages.last + (num_std_devs * standard_deviations.last)
    lower_band = moving_averages.last - (num_std_devs * standard_deviations.last)

    return [upper_band, lower_band]
  end

end
