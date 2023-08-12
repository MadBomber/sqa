# lib/sqa/indicator/fibonacci_retracement.rb

class SQA::Indicator; class << self

  def fibonacci_retracement(
        start_price,  # Float starting price of the range
        end_price     # Float ending price of the range
      )
    retracement_levels = []

    retracement_levels << end_price
    retracement_levels << start_price

    fibonacci_levels = [0.236, 0.382, 0.5, 0.618, 0.786]

    fibonacci_levels.each do |level|
      retracement_levels <<= start_price + (end_price - start_price) * level
    end

    retracement_levels # Array
  end
  alias_method :fr, :fibonacci_retracement

end; end

