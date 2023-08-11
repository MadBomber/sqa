# lib/sqa/indicators/stochastic_oscillator.rb

module SQA::Indicators

  # @param high_prices [Array] An array of high prices.
  # @param low_prices [Array] An array of low prices.
  # @param close_prices [Array] An array of closing prices.
  # @param period [Integer] The period for calculating the Stochastic Oscillator.
  # @param smoothing_period [Integer] The smoothing period for %K line.
  # @return [Array] An array of %K and %D values.
  #
  def stochastic_oscillator(high_prices, low_prices, close_prices, period, smoothing_period)
    k_values = []
    d_values = []

    close_prices.each_cons(period) do |closing_prices|
      highest_high = high_prices.max(period)
      lowest_low = low_prices.min(period)

      current_close = closing_prices.last
      k_value = (current_close - lowest_low) / (highest_high - lowest_low) * 100
      k_values << k_value
    end

    k_values.each_cons(smoothing_period) do |k_values_subset|
      d_value = k_values_subset.sum / smoothing_period.to_f
      d_values << d_value
    end

    [k_values, d_values]
  end

end

