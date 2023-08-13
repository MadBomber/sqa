# lib/sqa/indicator/momentum.rb

class SQA::Indicator; class << self

  # @param prices [Array]
  # @param period [Integer]
  #
  # @return [Float]
  #
  def momentum(
        prices, # Array of prices
        period  # Integer number of entries to consider
      )

    momentums = []

    prices.each_cons(period) do |window|
      current_price = window.last.to_f
      past_price    = window.first.to_f
      momentums    << 10.0 * ( (current_price - past_price) / past_price)
    end

    momentums  # Array
  end
  alias_method :m, :momentum

end; end

