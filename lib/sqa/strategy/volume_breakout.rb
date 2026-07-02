# lib/sqa/strategy/volume_breakout.rb
# frozen_string_literal: true

# Volume Breakout strategy
# Buy when price breaks above resistance with high volume
# Sell when price breaks below support with high volume
#
class SQA::Strategy::VolumeBreakout
  def self.trade(vector)
    return :hold unless sufficient_data?(vector)

    prices = vector.prices
    volumes = vector.volumes

    return :hold if SQAI.sma(prices, period: 20).nil?

    breakout_signal(prices, volumes)
  rescue => e
    warn "VolumeBreakout strategy error: #{e.message}"
    :hold
  end

  # Guard: do we have enough price/volume history to evaluate a breakout?
  def self.sufficient_data?(vector)
    vector.respond_to?(:prices) &&
      vector.respond_to?(:volumes) &&
      (vector.prices&.size&.>= 20) &&
      (vector.volumes&.size&.>= 20)
  end
  private_class_method :sufficient_data?

  # Determine :buy/:sell/:hold from the current price/volume breakout state
  def self.breakout_signal(prices, volumes)
    current_price = prices.last
    prev_price = prices[-2]
    current_volume = volumes.last

    avg_volume = volumes.last(20).sum / 20.0
    volume_threshold = avg_volume * 1.5  # High volume threshold (1.5x average)

    # Recent high/low (resistance/support), excluding the current price
    lookback_prices = prices[...-1].last(20)
    recent_high = lookback_prices.max
    recent_low = lookback_prices.min

    high_volume = current_volume > volume_threshold

    if current_price > recent_high && prev_price <= recent_high && high_volume
      :buy
    elsif current_price < recent_low && prev_price >= recent_low && high_volume
      :sell
    else
      :hold
    end
  end
  private_class_method :breakout_signal
end
