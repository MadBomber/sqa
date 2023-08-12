# lib/sqa/indicator/average_true_range.rb

# See Also: true_range

class SQA::Indicator; class << self

  def average_true_range(
        high_prices,  # Array of the day's high price
        low_prices,   # Array of the day's low price
        close_prices, # Array of the day's closing price
        period        # Integer the number of days to consider
      )
    true_ranges = true_range(high_prices, low_prices, close_prices)
    atr_values  = []

    true_ranges.each_with_index do |true_range, index|
      if index < period - 1
        atr_values << nil
      elsif index == period - 1
        atr_values << true_ranges[0..index].sum / period.to_f
      else
        atr_values << (atr_values[index - 1] * (period - 1) + true_range) / period.to_f
      end
    end

    atr_values # Array
  end
  alias_method :atr, :average_true_range

end; end
