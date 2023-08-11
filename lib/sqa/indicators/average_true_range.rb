# lib/sqa/indicators/average_true_range.rb

module SQA::Indicators

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
