# lib/sqa/strategy/macd.rb
# frozen_string_literal: true

# MACD (Moving Average Convergence Divergence) crossover strategy
# Buy when MACD line crosses above signal line (bullish)
# Sell when MACD line crosses below signal line (bearish)
#
class SQA::Strategy::MACD
  def self.trade(vector)
    return :hold unless vector.respond_to?(:prices) && vector.prices&.size >= 35

    prices = vector.prices

    # Calculate MACD using SQAI (returns macd, signal, histogram)
    macd_line, signal_line, histogram = SQAI.macd(
      prices,
      fast_period: 12,
      slow_period: 26,
      signal_period: 9
    )

    return :hold if macd_line.nil? || signal_line.nil? || macd_line.size < 2

    # Get current and previous values
    current_macd = macd_line[-1]
    current_signal = signal_line[-1]
    prev_macd = macd_line[-2]
    prev_signal = signal_line[-2]

    # Bullish crossover: MACD crosses above signal
    if prev_macd <= prev_signal && current_macd > current_signal
      :buy

    # Bearish crossover: MACD crosses below signal
    elsif prev_macd >= prev_signal && current_macd < current_signal
      :sell

    # No crossover
    else
      :hold
    end
  rescue => e
    warn "MACD strategy error: #{e.message}"
    :hold
  end
end
