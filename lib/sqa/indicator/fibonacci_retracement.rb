# lib/sqa/indicator/fibonacci_retracement.rb

class SQA::Indicator; class << self

  def fibonacci_retracement(
        swing_high,   # Float peak price in a period - peak
        swing_low     # Float bottom price in a period - valley
      )
    retracement_levels = []

    fibonacci_levels = [0.236, 0.382, 0.5, 0.618, 0.786]

    fibonacci_levels.each do |level|
      retracement_levels << swing_low + (swing_high - swing_low) * level
    end


    retracement_levels # Array
  end
  alias_method :fr, :fibonacci_retracement

end; end

