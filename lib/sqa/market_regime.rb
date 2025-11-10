# frozen_string_literal: true

# SQA::MarketRegime - Detect market regimes (bull/bear/sideways)
#
# Market regimes are distinct market conditions that affect trading strategy
# effectiveness. This module identifies regimes based on:
# - Trend direction (bull/bear)
# - Volatility levels (VIX, ATR)
# - Market breadth
# - Momentum indicators
#
# Example:
#   regime = SQA::MarketRegime.detect(stock)
#   # => { type: :bull, volatility: :low, strength: :strong, dates: [...] }

module SQA
  module MarketRegime
    class << self
      # Detect current market regime for a stock
      #
      # @param stock [SQA::Stock] Stock to analyze
      # @param lookback [Integer] Days to look back for regime detection
      # @param window [Integer] Alias for lookback (for backward compatibility)
      # @return [Hash] Regime metadata
      #
      def detect(stock, lookback: nil, window: nil)
        # Accept both lookback and window for backward compatibility
        # lookback takes precedence if both provided
        period = lookback || window || 60

        prices = stock.df["adj_close_price"].to_a
        return { type: :unknown } if prices.size < period

        recent_prices = prices.last(period)

        {
          type: detect_trend(recent_prices),
          volatility: detect_volatility(recent_prices),
          strength: detect_strength(recent_prices),
          lookback_days: period,
          detected_at: Time.now
        }
      end

      # Detect market regimes across entire history
      #
      # Splits historical data into regime periods
      #
      # @param stock [SQA::Stock] Stock to analyze
      # @param window [Integer] Rolling window for regime detection
      # @return [Array<Hash>] Array of regime periods
      #
      def detect_history(stock, window: 60)
        prices = stock.df["adj_close_price"].to_a
        regimes = []
        current_regime = nil
        regime_start = 0

        (window...prices.size).each do |i|
          window_prices = prices[(i - window)..i]
          regime_type = detect_trend(window_prices)
          volatility = detect_volatility(window_prices)

          # Check if regime changed
          if current_regime != regime_type
            # Save previous regime
            if current_regime
              regimes << {
                type: current_regime,
                start_index: regime_start,
                end_index: i - 1,
                duration: i - regime_start,
                volatility: volatility
              }
            end

            current_regime = regime_type
            regime_start = i
          end
        end

        # Add final regime
        if current_regime
          regimes << {
            type: current_regime,
            start_index: regime_start,
            end_index: prices.size - 1,
            duration: prices.size - regime_start,
            volatility: detect_volatility(prices[regime_start..-1])
          }
        end

        regimes
      end

      # Classify regime type based on trend
      #
      # @param prices [Array<Float>] Price array
      # @return [Symbol] :bull, :bear, or :sideways
      #
      def detect_trend(prices)
        return :unknown if prices.size < 20

        # Simple moving averages
        sma_short = prices.last(20).sum / 20.0
        sma_long = prices.last(60).sum / 60.0 rescue sma_short

        # Price vs moving averages
        current_price = prices.last

        # Calculate trend strength
        pct_above_sma = ((current_price - sma_long) / sma_long * 100.0)

        if pct_above_sma > 5 && sma_short > sma_long
          :bull
        elsif pct_above_sma < -5 && sma_short < sma_long
          :bear
        else
          :sideways
        end
      end

      # Detect volatility regime
      #
      # @param prices [Array<Float>] Price array
      # @return [Symbol] :low, :medium, or :high
      #
      def detect_volatility(prices)
        return :unknown if prices.size < 20

        # Calculate daily returns
        returns = []
        prices.each_cons(2) do |prev, curr|
          returns << ((curr - prev) / prev * 100.0).abs
        end

        avg_volatility = returns.sum / returns.size

        if avg_volatility < 1.0
          :low
        elsif avg_volatility < 2.5
          :medium
        else
          :high
        end
      end

      # Detect trend strength
      #
      # @param prices [Array<Float>] Price array
      # @return [Symbol] :weak, :moderate, or :strong
      #
      def detect_strength(prices)
        return :unknown if prices.size < 20

        # Look at consistency of direction
        up_days = 0
        down_days = 0

        prices.each_cons(2) do |prev, curr|
          if curr > prev
            up_days += 1
          else
            down_days += 1
          end
        end

        total_days = up_days + down_days
        directional_pct = [up_days, down_days].max.to_f / total_days * 100

        if directional_pct > 70
          :strong
        elsif directional_pct > 55
          :moderate
        else
          :weak
        end
      end

      # Split data by regime
      #
      # @param stock [SQA::Stock] Stock to analyze
      # @return [Hash] Data grouped by regime type
      #
      def split_by_regime(stock)
        regimes = detect_history(stock)
        prices = stock.df["adj_close_price"].to_a

        grouped = { bull: [], bear: [], sideways: [] }

        regimes.each do |regime|
          regime_prices = prices[regime[:start_index]..regime[:end_index]]
          grouped[regime[:type]] << {
            prices: regime_prices,
            start_index: regime[:start_index],
            end_index: regime[:end_index],
            duration: regime[:duration]
          }
        end

        grouped
      end
    end
  end
end
