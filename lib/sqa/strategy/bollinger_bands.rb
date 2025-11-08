# lib/sqa/strategy/bollinger_bands.rb
# frozen_string_literal: true

# Bollinger Bands trading strategy
# Buy when price touches lower band (oversold)
# Sell when price touches upper band (overbought)
#
class SQA::Strategy::BollingerBands
  def self.trade(vector)
    return :hold unless vector.respond_to?(:prices) && vector.prices&.size >= 20

    prices = vector.prices
    period = 20
    std_dev = 2.0

    # Calculate Bollinger Bands using SQAI
    upper, middle, lower = SQAI.bbands(prices, period: period, nbdev_up: std_dev, nbdev_down: std_dev)

    return :hold if upper.nil? || lower.nil?

    current_price = prices.last
    upper_band = upper.last
    lower_band = lower.last
    middle_band = middle.last

    # Buy signal: price at or below lower band (oversold)
    if current_price <= lower_band
      :buy

    # Sell signal: price at or above upper band (overbought)
    elsif current_price >= upper_band
      :sell

    # Hold: price between bands
    else
      :hold
    end
  rescue => e
    warn "BollingerBands strategy error: #{e.message}"
    :hold
  end
end
