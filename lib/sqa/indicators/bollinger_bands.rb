# fin_tech/lib/fin_tech/bollinger_bands.rb

module FinTech

  #######################################################################
  # Bollinger Bands
  #
  # This method takes in an array of historical prices for a stock, a
  # period (the number of days to calculate the moving average and standard
  # deviation over), and the number of standard deviations to use for the
  # upper and lower Bollinger Bands. It uses the `moving_averages` method to
  # calculate the moving average for the given period, and then calculates the
  # standard deviation of the closing prices for each window of the given period.
  # Finally, it calculates the upper and lower Bollinger Bands based on the moving
  # average and standard deviation, and returns an array containing the upper and
  # lower bands.
  #
  # The `num_std_dev` parameter in the Bollinger Bands method specifies the number
  # of standard deviations to use for the upper and lower bands. The default
  # value for this parameter can depend on the specific security being analyzed
  # and the time period being used.
  #
  # A common default value for `num_std_dev` is 2, which corresponds to the
  # standard deviation of the price data over the given time period. Using a
  # value of 2 for `num_std_dev` will result in the upper and lower bands being
  # placed at a distance of two standard deviations from the moving average.
  #
  # However, the optimal value for `num_std_dev` can vary depending on the
  # volatility of the security being analyzed. For highly volatile securities, a
  # larger value for `num_std_dev` may be more appropriate, while for less
  # volatile securities, a smaller value may be more appropriate.
  #
  # Ultimately, the best default value for `num_std_dev` will depend on the
  # specific use case and should be chosen based on the characteristics of the
  # security being analyzed and the preferences of the analyst.
  #
  # The difference between the upper and lower bands can
  # be an indicator of how volatile the stock is.

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
