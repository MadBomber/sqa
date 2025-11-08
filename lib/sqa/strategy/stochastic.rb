# lib/sqa/strategy/stochastic.rb
# frozen_string_literal: true

# Stochastic Oscillator crossover strategy
# Buy when %K crosses above %D in oversold territory (< 20)
# Sell when %K crosses below %D in overbought territory (> 80)
#
class SQA::Strategy::Stochastic
  def self.trade(vector)
    return :hold unless vector.respond_to?(:prices) && vector.prices&.size >= 14

    prices = vector.prices

    # We need high, low, close arrays for stochastic
    # For simplicity, use prices as close, and approximate high/low from recent range
    # In a real scenario, you'd get actual high/low from the stock data
    high = prices.dup
    low = prices.dup
    close = prices

    # Calculate Stochastic using SQAI
    # Returns fastk and fastd (or slowk and slowd depending on the function)
    stoch_k, stoch_d = SQAI.stoch(
      high,
      low,
      close,
      fastk_period: 14,
      slowk_period: 3,
      slowd_period: 3
    )

    return :hold if stoch_k.nil? || stoch_d.nil? || stoch_k.size < 2

    # Get current and previous values
    current_k = stoch_k[-1]
    current_d = stoch_d[-1]
    prev_k = stoch_k[-2]
    prev_d = stoch_d[-2]

    # Oversold threshold
    oversold = 20.0
    # Overbought threshold
    overbought = 80.0

    # Buy signal: %K crosses above %D in oversold territory
    if current_k < oversold && prev_k <= prev_d && current_k > current_d
      :buy

    # Sell signal: %K crosses below %D in overbought territory
    elsif current_k > overbought && prev_k >= prev_d && current_k < current_d
      :sell

    else
      :hold
    end
  rescue => e
    warn "Stochastic strategy error: #{e.message}"
    :hold
  end
end
