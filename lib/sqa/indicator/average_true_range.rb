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

    # debug_me{[ :period, :true_ranges ]}

    window_span = period - 1

    true_ranges.size.times do |inx|
      start_inx = inx - window_span
      end_inx   = start_inx + window_span

      start_inx = 0 if start_inx < 0

      window    = true_ranges[start_inx..end_inx]

      # debug_me{[
      #   :inx,
      #   :start_inx,
      #   :end_inx,
      #   :window,
      #   "window.mean"
      # ]}

      atr_values << window.mean
    end

    atr_values # Array
  end
  alias_method :atr, :average_true_range

end; end
