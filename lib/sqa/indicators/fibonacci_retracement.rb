# lib/sqa/indicators/fibonacci_retracement.rb

module SQA::Indicators

  # @param start_price [Float] The starting price of the range.
  # @param end_price [Float] The ending price of the range.
  # @return [Array] An array of Fibonacci Retracement levels.
  #
  def fibonacci_retracement(start_price, end_price)
    retracement_levels = []

    retracement_levels << end_price
    retracement_levels << start_price

    fibonacci_levels = [0.236, 0.382, 0.5, 0.618, 0.786]

    fibonacci_levels.each do |level|
      retracement = start_price + (end_price - start_price) * level
      retracement_levels << retracement
    end

    retracement_levels
  end

end

