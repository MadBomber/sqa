# lib/sqa/indicator/true_strength_index.rb

class SQA::Indicator; class << self

  def true_strength_index(prices, long_period, short_period)
    return [] if prices.size < long_period + short_period # Not enough data
      
    # Step 1: Calculate Price Changes and Absolute Price Changes
    price_changes           = prices.each_cons(2).map { |p1, p2| p2 - p1 }
    absolute_price_changes  = price_changes.map(&:abs)

    # Step 2: Smooth Price Changes and Absolute Price Changes (first smoothing)
    smoothed_price_changes          = ema(price_changes, long_period)
    smoothed_absolute_price_changes = ema(absolute_price_changes, long_period)

    # Step 3: Smooth the above EMAs (second smoothing)
    double_smoothed_price_changes           = ema(smoothed_price_changes, short_period)
    double_smoothed_absolute_price_changes  = ema(smoothed_absolute_price_changes, short_period)

    # Step 4: Calculate TSI values
    tsi_values = 
      double_smoothed_price_changes.zip(
        double_smoothed_absolute_price_changes
      ).map do |double_smooth_price, double_smooth_abs_price|
      100 * double_smooth_price / double_smooth_abs_price
    end
    
    # TSI is not defined for first (long_period + short_period - 1) days
    [nil] * (long_period + short_period - 1) + tsi_values
  end
  alias_method :tsi, :true_strength_index

end; end


__END__

# Example usage:
# prices = [ ... ] # An array of numeric prices
# long_period = 25
# short_period = 13
# tsi = calculate_tsi(prices, long_period, short_period)
# puts tsi


This `calculate_tsi` method calculates the TSI values for an array of prices with the given long and short periods. It follows these steps:

1. It calculates the price changes and corresponding absolute price changes.
2. It applies an EMA smoothing for both sets of changes with the longer period (first smoothing).
3. It again smooths the results from step 2 with the shorter period (second smoothing).
4. It calculates the TSI values using the double smoothed changes.

The `exponential_moving_average` helper method is used to calculate the EMA based on the provided period. The method is called within `calculate_tsi` to smooth the price changes and then to smooth the resulting EMAs.

Finally, the method returns an array of TSI values, where the first `(long_period + short_period - 1)` values will be `nil` since the TSI is not defined for this initial range due to the lack of enough previous data.

