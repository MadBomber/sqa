# lib/sqa/indicators/true_range.rb

module SQA::Indicators

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
end
