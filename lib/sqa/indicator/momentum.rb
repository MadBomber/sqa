# lib/sqa/indicator/momentum.rb

module SQA::Indicator; class << self

  # @param prices [Array]
  # @param period [Integer]
  #
  # @return [Float]
  #
  def momentum(
        prices, # Array of prices
        period  # Integer number of entries to consider
      )
    return 0.0 if prices.length <= period

    current_price = prices.last
    past_price    = prices.last(period).first
    change        = (current_price - past_price) / past_price.to_f
    momentum      = change * 100.0

    momentum  # Float expressed as a percentage change
  end
  alias_method :m, :momentum

end; end

