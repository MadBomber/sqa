# lib/sqa/indicator/stochastic_oscillator.rb

module SQA::Indicator; class << self

  # @param high_prices [Array]
  # @param low_prices [Array]
  # @param close_prices [Array]
  # @param period [Integer]
  # @param smoothing_period [Integer]
  #
  # @return [Array] An array of %K and %D values.
  #
  def stochastic_oscillator(
        high_prices,      # Array of high prices
        low_prices,       # Array of low prices
        closing_prices,   # Array of closing prices
        period,           # Integer The period for calculating the Stochastic Oscillator
        smoothing_period  # Integer The smoothing period for %K line
      )
    k_values = []
    d_values = []

    closing_prices.each_cons(period) do |closing_prices_subset|
      highest_high  = high_prices.max(period)
      lowest_low    = low_prices.min(period)
      current_close = closing_prices_subset.last
      k_values     << (current_close - lowest_low) / (highest_high - lowest_low) * 100 # Calculate the k_value
    end

    k_values.each_cons(smoothing_period) do |k_values_subset|
      d_values << k_values_subset.sum / smoothing_period.to_f # Calculate the d_value
    end

    [k_values, d_values]
  end
  alias_method :so, :stochastic_oscillator

end; end

