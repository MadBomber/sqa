# lib/sqa/strategy/volume_breakout.rb
# frozen_string_literal: true

# Volume Breakout strategy
# Buy when price breaks above resistance with high volume
# Sell when price breaks below support with high volume
#
class SQA::Strategy::VolumeBreakout
  def self.trade(vector)
    return :hold unless vector.respond_to?(:prices) &&
                        vector.respond_to?(:volumes) &&
                        vector.prices&.size >= 20 &&
                        vector.volumes&.size >= 20

    prices = vector.prices
    volumes = vector.volumes

    # Calculate moving averages
    sma_20 = SQAI.sma(prices, period: 20)
    return :hold if sma_20.nil?

    current_price = prices.last
    prev_price = prices[-2]
    current_volume = volumes.last

    # Calculate average volume
    avg_volume = volumes.last(20).sum / 20.0

    # High volume threshold (1.5x average)
    volume_threshold = avg_volume * 1.5

    # Get recent high and low (resistance and support)
    recent_high = prices.last(20).max
    recent_low = prices.last(20).min

    # Buy signal: price breaks above recent high with high volume
    if current_price > recent_high &&
       prev_price <= recent_high &&
       current_volume > volume_threshold
      :buy

    # Sell signal: price breaks below recent low with high volume
    elsif current_price < recent_low &&
          prev_price >= recent_low &&
          current_volume > volume_threshold
      :sell

    else
      :hold
    end
  rescue => e
    warn "VolumeBreakout strategy error: #{e.message}"
    :hold
  end
end
