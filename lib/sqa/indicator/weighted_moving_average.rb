# sqa/lib/sqa/indicator/weighted_moving_average.rb

class SQA::Indicator; class << self

  # NOTE: sometimes daily volume can be used as a
  #       weight for the price; but that would be
  #       in a different method than this one.

  def weighted_moving_average(prices, period)
    return [] if prices.length < period
    
    weights         = (1..period).to_a.reverse
    sum_of_weights  = weights.reduce(:+)

    wm_averages = []

    prices.each_cons(period) do |price_window|
      weighted_prices = price_window.zip(weights).map { |price, weight| price * weight }
      wma_value       = weighted_prices.reduce(:+) / sum_of_weights.to_f
      wm_averages    << wma_value
    end

    wm_averages
  end
  alias_method :wma, :weighted_moving_average

end ; end


__END__


# Example Usage:
prices = [10, 11, 12, 13, 14, 15, 16]
period = 3
wm_avgs = weighted_moving_average(prices, period).map{|v| v.round(3)}
puts "Weighted Moving Averages: #{wm_avgs}"
#=> Weighted Moving Averages: [10.666666666666666, 11.666666666666666, 12.666666666666666, 13.666666666666666, 14.666666666666666]
