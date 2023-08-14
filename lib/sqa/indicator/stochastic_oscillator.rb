# lib/sqa/indicator/stochastic_oscillator.rb

class SQA::Indicator; class << self

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

    closing_prices.each_cons(period) do |window|
      highest_high  = high_prices.max(period)
      lowest_low    = low_prices.min(period)
      current_close = window.last
      k_values     << (current_close - lowest_low) / (highest_high - lowest_low) * 100 # Calculate the k_value
    end

    k_values.each_cons(smoothing_period) do |k_values_subset|
      d_values << k_values_subset.sum / smoothing_period.to_f # Calculate the d_value
    end

    [k_values, d_values]
  end
  alias_method :so, :stochastic_oscillator


  def stochastic_oscillator2(
        prices, # Array of prices
        period  # Integer number of events to consider
      )
    k_values = []
    d_values = []

    prices.each_cons(period) do |window|
      low           = window.min  # Lowest  price in the period
      high          = window.max  # Highest price in the period
      current_price = window.last # Current closing price

      k_values << (current_price - low) * 100 / (high - low)
    end

    k_values.each_cons(period) do |window|
      d_values << window.mean
    end

    {
      k: k_values,
      d: d_values
    }
  end
  alias_method :so2, :stochastic_oscillator2



end; end

