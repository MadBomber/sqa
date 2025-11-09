# lib/sqa/multi_timeframe.rb
# frozen_string_literal: true

module SQA
  ##
  # MultiTimeframe - Analyze patterns across multiple timeframes
  #
  # Provides methods for:
  # - Timeframe conversion (daily → weekly → monthly)
  # - Multi-timeframe signal confirmation
  # - Trend alignment across timeframes
  # - Support/resistance across timeframes
  #
  # Common timeframe strategy:
  # - Use higher timeframe for trend direction
  # - Use lower timeframe for entry timing
  #
  # @example Multi-timeframe trend alignment
  #   mta = SQA::MultiTimeframe.new(stock: stock)
  #   alignment = mta.trend_alignment
  #   # => { daily: :up, weekly: :up, monthly: :up, aligned: true }
  #
  class MultiTimeframe
    attr_reader :stock, :timeframes

    ##
    # Initialize multi-timeframe analyzer
    #
    # @param stock [SQA::Stock] Stock object with daily data
    #
    def initialize(stock:)
      @stock = stock
      @timeframes = {}

      # Convert daily data to other timeframes
      convert_timeframes
    end

    ##
    # Convert daily data to weekly and monthly
    #
    def convert_timeframes
      daily_data = @stock.df.data

      @timeframes[:daily] = daily_data
      @timeframes[:weekly] = resample(daily_data, period: 5)
      @timeframes[:monthly] = resample(daily_data, period: 21)
    end

    ##
    # Check trend alignment across timeframes
    #
    # @param lookback [Integer] Periods to look back for trend
    # @return [Hash] Trend direction for each timeframe
    #
    def trend_alignment(lookback: 20)
      trends = {}

      @timeframes.each do |timeframe, data|
        prices = data["adj_close_price"].to_a
        recent = prices.last([lookback, prices.size].min)

        # Simple trend: compare current to average
        current = recent.last
        avg = recent.sum / recent.size.to_f

        trends[timeframe] = if current > avg * 1.02
                              :up
                            elsif current < avg * 0.98
                              :down
                            else
                              :sideways
                            end
      end

      # Check if all timeframes aligned
      all_up = trends.values.all? { |t| t == :up }
      all_down = trends.values.all? { |t| t == :down }

      trends[:aligned] = all_up || all_down
      trends[:direction] = if all_up
                             :bullish
                           elsif all_down
                             :bearish
                           else
                             :mixed
                           end

      trends
    end

    ##
    # Generate multi-timeframe signal
    #
    # Uses higher timeframe for trend, lower for timing.
    #
    # @param strategy_class [Class] Strategy to apply
    # @param higher_timeframe [Symbol] Timeframe for trend (:weekly, :monthly)
    # @param lower_timeframe [Symbol] Timeframe for entry (:daily, :weekly)
    # @return [Symbol] :buy, :sell, or :hold
    #
    def signal(strategy_class:, higher_timeframe: :weekly, lower_timeframe: :daily)
      # Get trend from higher timeframe
      higher_data = @timeframes[higher_timeframe]
      higher_prices = higher_data["adj_close_price"].to_a

      higher_trend = if higher_prices.last > higher_prices[-10..-1].sum / 10.0
                       :up
                     else
                       :down
                     end

      # Get signal from lower timeframe
      lower_data = @timeframes[lower_timeframe]
      lower_vector = create_vector(lower_data)

      lower_signal = strategy_class.trade(lower_vector)

      # Combine: only take trades aligned with higher timeframe
      case higher_trend
      when :up
        lower_signal == :buy ? :buy : :hold
      when :down
        lower_signal == :sell ? :sell : :hold
      else
        :hold
      end
    end

    ##
    # Find support/resistance levels across timeframes
    #
    # Levels that appear on multiple timeframes are stronger.
    #
    # @param tolerance [Float] Price tolerance for matching levels (default: 0.02 for 2%)
    # @return [Hash] Support and resistance levels
    #
    def support_resistance(tolerance: 0.02)
      all_levels = { support: [], resistance: [] }

      @timeframes.each do |timeframe, data|
        prices = data["adj_close_price"].to_a
        levels = find_levels(prices)

        all_levels[:support] += levels[:support].map { |l| { price: l, timeframe: timeframe } }
        all_levels[:resistance] += levels[:resistance].map { |l| { price: l, timeframe: timeframe } }
      end

      # Find levels that appear on multiple timeframes
      strong_support = cluster_levels(all_levels[:support], tolerance)
      strong_resistance = cluster_levels(all_levels[:resistance], tolerance)

      {
        support: strong_support,
        resistance: strong_resistance,
        current_price: @stock.df.data["adj_close_price"].to_a.last
      }
    end

    ##
    # Calculate indicators for each timeframe
    #
    # @param indicator [Symbol] Indicator to calculate
    # @param options [Hash] Indicator options
    # @return [Hash] Indicator values for each timeframe
    #
    def indicators(indicator:, **options)
      results = {}

      @timeframes.each do |timeframe, data|
        prices = data["adj_close_price"].to_a

        results[timeframe] = case indicator
                             when :sma
                               SQAI.sma(prices, **options)
                             when :ema
                               SQAI.ema(prices, **options)
                             when :rsi
                               SQAI.rsi(prices, **options)
                             when :macd
                               SQAI.macd(prices, **options)
                             else
                               nil
                             end
      end

      results
    end

    ##
    # Detect divergence across timeframes
    #
    # Divergence occurs when price and indicator move in opposite directions.
    #
    # @return [Hash] Divergence information
    #
    def detect_divergence
      divergences = {}

      @timeframes.each do |timeframe, data|
        prices = data["adj_close_price"].to_a
        rsi = SQAI.rsi(prices, period: 14)

        next if prices.size < 20 || rsi.size < 20

        # Compare last 10 periods
        price_trend = prices[-1] > prices[-10]
        rsi_trend = rsi[-1] > rsi[-10]

        divergences[timeframe] = if price_trend && !rsi_trend
                                   :bearish_divergence
                                 elsif !price_trend && rsi_trend
                                   :bullish_divergence
                                 else
                                   :no_divergence
                                 end
      end

      divergences
    end

    ##
    # Check if timeframes confirm each other
    #
    # @param strategy_class [Class] Strategy to use
    # @return [Hash] Confirmation status
    #
    def confirmation(strategy_class:)
      signals = {}

      @timeframes.each do |timeframe, data|
        vector = create_vector(data)
        signals[timeframe] = strategy_class.trade(vector)
      end

      # Check agreement
      buy_count = signals.values.count(:buy)
      sell_count = signals.values.count(:sell)

      {
        signals: signals,
        confirmed: buy_count >= 2 || sell_count >= 2,
        consensus: if buy_count >= 2
                     :buy
                   elsif sell_count >= 2
                     :sell
                   else
                     :hold
                   end
      }
    end

    private

    ##
    # Resample daily data to longer timeframes
    #
    # @param daily_data [Polars::DataFrame] Daily data
    # @param period [Integer] Number of days per period
    # @return [Polars::DataFrame] Resampled data
    #
    def resample(daily_data, period:)
      prices = daily_data["adj_close_price"].to_a
      volumes = daily_data["volume"].to_a

      resampled_prices = []
      resampled_volumes = []

      (0...prices.size).step(period) do |i|
        chunk_prices = prices[i, period]
        chunk_volumes = volumes[i, period]

        next if chunk_prices.nil? || chunk_prices.empty?

        # OHLC would be better, but we'll use close for simplicity
        resampled_prices << chunk_prices.last
        resampled_volumes << chunk_volumes.sum
      end

      # Create new DataFrame
      SQA::DataFrame.new(
        {
          "adj_close_price" => resampled_prices,
          "volume" => resampled_volumes
        }
      ).data
    end

    ##
    # Find support/resistance levels using local extrema
    #
    # @param prices [Array<Float>] Price array
    # @return [Hash] Support and resistance levels
    #
    def find_levels(prices)
      return { support: [], resistance: [] } if prices.size < 20

      support = []
      resistance = []

      window = 5

      (window...(prices.size - window)).each do |idx|
        current = prices[idx]
        left = prices[(idx - window)...idx]
        right = prices[(idx + 1)..(idx + window)]

        # Local minimum (support)
        if left.all? { |p| current <= p } && right.all? { |p| current <= p }
          support << current
        end

        # Local maximum (resistance)
        if left.all? { |p| current >= p } && right.all? { |p| current >= p }
          resistance << current
        end
      end

      { support: support, resistance: resistance }
    end

    ##
    # Cluster similar levels across timeframes
    #
    # @param levels [Array<Hash>] Levels with { price:, timeframe: }
    # @param tolerance [Float] Price tolerance
    # @return [Array<Hash>] Clustered levels
    #
    def cluster_levels(levels, tolerance)
      return [] if levels.empty?

      clusters = []

      levels.each do |level|
        # Find existing cluster
        cluster = clusters.find do |c|
          (c[:price] - level[:price]).abs / c[:price] < tolerance
        end

        if cluster
          # Add to existing cluster
          cluster[:timeframes] << level[:timeframe]
          cluster[:count] += 1
          # Update average price
          cluster[:price] = (cluster[:price] * (cluster[:count] - 1) + level[:price]) / cluster[:count]
        else
          # Create new cluster
          clusters << {
            price: level[:price],
            timeframes: [level[:timeframe]],
            count: 1
          }
        end
      end

      # Sort by strength (number of timeframes)
      clusters.sort_by { |c| -c[:count] }
    end

    ##
    # Create vector for strategy from timeframe data
    #
    # @param data [Polars::DataFrame] Timeframe data
    # @return [OpenStruct] Vector for strategy
    #
    def create_vector(data)
      prices = data["adj_close_price"].to_a

      require 'ostruct'
      OpenStruct.new(
        prices: prices,
        close: prices.last,
        rsi: SQAI.rsi(prices, period: 14).last,
        sma_20: SQAI.sma(prices, period: 20).last,
        ema_12: SQAI.ema(prices, period: 12).last
      )
    end
  end
end
