# lib/sqa/indicators/true_range.rb

module SQA::Indicators

  #######################################################################
  # Calculates the True Range (TR) for a given set of price data.
  #
  # The True Range is a measure of the price volatility of a security over a given
  # period.  It is calculated as the greatest of the following three values:
  # - The difference between the current high and the current low.
  # - The absolute value of the difference between the current high and the previous
  #   close.
  # - The absolute value of the difference between the current low and the previous
  #   close.
  #
  # The True Range helps to capture the true extent of price movement, taking
  # into account potential gaps or price jumps between periods. It is often used
  # as a component in calculating other indicators, such as the Average True Range.
  #
  # @param high_prices [Array] An array of high prices.
  # @param low_prices [Array] An array of low prices.
  # @param previous_closes [Array] An array of previous closing prices.
  # @return [Array] An array of True Range values.
  #
  def true_range(high_prices, low_prices, previous_closes)
    true_ranges = []

    high_prices.each_with_index do |high, index|
      low = low_prices[index]
      previous_close = previous_closes[index]

      true_range = [
        high - low,
        (high - previous_close).abs,
        (low - previous_close).abs
      ].max

      true_ranges << true_range
    end

    true_ranges
  end
  alias_method :tr, :true_range


  # Calculates the Average True Range (ATR) for a given set of price data.
  #
  # The Average True Range is an indicator that calculates the average of the
  # True Range values over a specified period. It provides a measure of the
  # average volatility of a security over that period.
  #
  # The ATR is commonly used to assess the volatility of a security, identify
  # potential trend reversals, and determine appropriate stop-loss levels. Higher
  # ATR values indicate higher volatility, while lower ATR values indicate lower
  # volatility.
  #
  # For example, a 14-day Average True Range would calculate the average of the
  # True Range values over the past 14 trading days. Traders and analysts may
  # use this indicator to set stop-loss levels based on the average volatility
  # of the security.
  #
  # @param high_prices [Array] An array of high prices.
  # @param low_prices [Array] An array of low prices.
  # @param close_prices [Array] An array of closing prices.
  # @param period [Integer] The period for calculating the ATR.
  # @return [Array] An array of Average True Range values.
  #
  def average_true_range(high_prices, low_prices, close_prices, period)
    true_ranges = calculate_true_range(high_prices, low_prices, close_prices)
    atr_values = []

    true_ranges.each_with_index do |true_range, index|
      if index < period - 1
        atr_values << nil
      elsif index == period - 1
        atr_values << true_ranges[0..index].sum / period.to_f
      else
        atr_values << (atr_values[index - 1] * (period - 1) + true_range) / period.to_f
      end
    end

    atr_values
  end
  alias_method :atr, :average_true_range

end
