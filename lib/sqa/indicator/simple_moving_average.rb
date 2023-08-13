# lib/sqa/indicator/simple_moving_average.rb

class SQA::Indicator; class << self

  def simple_moving_average(
        prices, # Array of prices
        period  # Integer how many to consider at a time
      )
    moving_averages = []

    (0..period-2).to_a.each do |x|
      moving_averages << prices[0..x].mean
    end

    prices.each_cons(period) do |window|
      moving_averages << window.mean
    end

    moving_averages # Array
  end
  alias_method :sma, :simple_moving_average

end; end

