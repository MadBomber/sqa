# lib/sqa/indicator/true_range.rb

# See Also: average_true_range

module SQA::Indicator; class << self

  # @param high_prices [Array]
  # @param low_prices [Array]
  # @param previous_closes [Array]
  #
  # @return [Array]
  #
  def true_range(
        high_prices,    # Array of high prices
        low_prices,     # Array of low prices
        previous_closes # Array of previous closing prices
      )
    true_ranges = []

    high_prices.each_with_index do |high, index|
      low = low_prices[index]
      previous_close = previous_closes[index]

      true_range = [
        high  - low,
        (high - previous_close).abs,
        (low  - previous_close).abs
      ].max

      true_ranges << true_range
    end

    true_ranges # Array of True Range values
  end
  alias_method :tr, :true_range

end; end
