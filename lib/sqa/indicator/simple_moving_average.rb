# lib/sqa/indicator/simple_moving_average.rb

module SQA::Indicator; class << self

  def simple_moving_average(
        prices, # Array of prices
        period  # Integer how many to consider at a time
      )
    moving_averages = []

    prices.each_cons(period) do |window|
      moving_average   = window.sum / period.to_f
      moving_averages << moving_average
    end

    moving_averages # Array
  end
  alias_method :sma, :simple_moving_average

end; end

