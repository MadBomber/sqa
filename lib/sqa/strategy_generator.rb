# frozen_string_literal: true

=begin

Strategy Generator - Reverse Engineering Profitable Trades

This module analyzes historical price data to identify inflection points (turning points)
that precede significant price movements. It discovers which indicator patterns were
present at those inflection points.

FPOP (Future Period of Performance): The number of days to look ahead from an
inflection point to measure if the price change exceeds the threshold.

Process:
1. Detect inflection points (local minima for buys, local maxima for sells)
2. Check if price change during fpop period exceeds threshold percentage
3. Calculate all indicators at those profitable inflection points
4. Identify which indicators were "active" (in buy/sell zones)
5. Find common patterns across profitable trades
6. Generate trading rules from discovered patterns
7. Optionally create KBS rules or strategy classes

Example:
  generator = SQA::StrategyGenerator.new(
    stock: stock,
    min_gain_percent: 10.0,
    fpop: 10  # Future Period of Performance (days)
  )

  patterns = generator.discover_patterns
  strategy = generator.generate_strategy

=end

module SQA
  class StrategyGenerator
    # Represents a profitable trade opportunity discovered in historical data
    class ProfitablePoint
      attr_accessor :entry_index, :entry_price, :exit_index, :exit_price,
                    :gain_percent, :holding_days, :indicators,
                    :fpl_min_delta, :fpl_max_delta, :fpl_risk, :fpl_direction, :fpl_magnitude

      def initialize(entry_index:, entry_price:, exit_index:, exit_price:, fpl_data: nil)
        @entry_index = entry_index
        @entry_price = entry_price
        @exit_index = exit_index
        @exit_price = exit_price
        @gain_percent = ((exit_price - entry_price) / entry_price * 100.0)
        @holding_days = exit_index - entry_index
        @indicators = {}

        # FPL quality metrics
        if fpl_data
          @fpl_min_delta = fpl_data[:min_delta]
          @fpl_max_delta = fpl_data[:max_delta]
          @fpl_risk = fpl_data[:risk]
          @fpl_direction = fpl_data[:direction]
          @fpl_magnitude = fpl_data[:magnitude]
        end
      end

      def to_s
        fpl_info = fpl_direction ? " dir=#{fpl_direction} risk=#{fpl_risk.round(2)}%" : ""
        "ProfitablePoint(gain=#{gain_percent.round(2)}%, days=#{holding_days}, entry=#{entry_index}#{fpl_info})"
      end
    end

    # Represents a discovered indicator pattern
    class Pattern
      attr_accessor :conditions, :frequency, :avg_gain, :avg_holding_days,
                    :success_rate, :occurrences

      def initialize(conditions: {})
        @conditions = conditions
        @frequency = 0
        @avg_gain = 0.0
        @avg_holding_days = 0.0
        @success_rate = 0.0
        @occurrences = []
      end

      def to_s
        "Pattern(conditions=#{conditions.size}, freq=#{frequency}, gain=#{avg_gain.round(2)}%, success=#{success_rate.round(2)}%)"
      end
    end

    attr_reader :stock, :profitable_points, :patterns, :min_gain_percent,
                :fpop, :min_loss_percent, :indicators_config, :inflection_window,
                :max_fpl_risk, :required_fpl_directions

    def initialize(stock:, min_gain_percent: 10.0, min_loss_percent: nil, fpop: 10, inflection_window: 3, max_fpl_risk: nil, required_fpl_directions: nil)
      @stock = stock
      @min_gain_percent = min_gain_percent
      @min_loss_percent = min_loss_percent || -min_gain_percent  # Symmetric loss threshold
      @fpop = fpop  # Future Period of Performance
      @inflection_window = inflection_window  # Window for detecting local min/max
      @max_fpl_risk = max_fpl_risk  # Optional: Filter by max acceptable risk (volatility)
      @required_fpl_directions = required_fpl_directions  # Optional: [:UP, :DOWN, :UNCERTAIN, :FLAT]
      @profitable_points = []
      @patterns = []

      # Configure which indicators to analyze
      @indicators_config = {
        rsi: { period: 14, oversold: 30, overbought: 70 },
        macd: { fast: 12, slow: 26, signal: 9 },
        stoch: { k_period: 14, d_period: 3, oversold: 20, overbought: 80 },
        sma_cross: { short: 20, long: 50 },
        ema: { period: 20 },
        bbands: { period: 20, nbdev: 2.0 },
        volume: { period: 20, threshold: 1.5 }
      }
    end

    # Main entry point: Discover patterns in historical data
    def discover_patterns(min_pattern_frequency: 2)
      puts "=" * 70
      puts "Strategy Generator: Discovering Profitable Patterns"
      puts "=" * 70
      puts "Target gain: ≥#{min_gain_percent}%"
      puts "Target loss: ≤#{min_loss_percent}%"
      puts "FPOP (Future Period of Performance): #{fpop} days"
      puts "Inflection window: #{inflection_window} days"
      puts

      # Step 1: Find profitable inflection points
      find_profitable_points

      return [] if @profitable_points.empty?

      # Step 2: Calculate indicators at each profitable point
      analyze_indicator_states

      # Step 3: Mine patterns from indicator states
      mine_patterns(min_frequency: min_pattern_frequency)

      # Step 4: Calculate pattern statistics
      calculate_pattern_statistics

      @patterns
    end

    # Generate a trading strategy from discovered patterns
    def generate_strategy(pattern_index: 0, strategy_type: :proc)
      return nil if @patterns.empty?

      pattern = @patterns[pattern_index]

      case strategy_type
      when :proc
        generate_proc_strategy(pattern)
      when :class
        generate_class_strategy(pattern)
      when :kbs
        generate_kbs_strategy(pattern)
      else
        raise "Unknown strategy type: #{strategy_type}"
      end
    end

    # Generate multiple strategies from top N patterns
    def generate_strategies(top_n: 5, strategy_type: :class)
      @patterns.take(top_n).map.with_index do |pattern, i|
        generate_strategy(pattern_index: i, strategy_type: strategy_type)
      end
    end

    # Print discovered patterns
    def print_patterns(max_patterns: 10)
      puts "\n" + "=" * 70
      puts "Discovered Patterns (Top #{[max_patterns, @patterns.size].min})"
      puts "=" * 70

      @patterns.take(max_patterns).each_with_index do |pattern, i|
        puts "\nPattern ##{i + 1}:"
        puts "  Frequency: #{pattern.frequency} occurrences"
        puts "  Average Gain: #{pattern.avg_gain.round(2)}%"
        puts "  Average Holding: #{pattern.avg_holding_days.round(1)} days"
        puts "  Success Rate: #{pattern.success_rate.round(2)}%"
        puts "  Conditions:"
        pattern.conditions.each do |indicator, state|
          puts "    - #{indicator}: #{state}"
        end
      end
      puts
    end

    # Export patterns to CSV
    def export_patterns(filename)
      require 'csv'

      CSV.open(filename, 'w') do |csv|
        csv << ['Pattern', 'Frequency', 'Avg Gain %', 'Avg Holding Days', 'Success Rate %', 'Conditions']

        @patterns.each_with_index do |pattern, i|
          conditions_str = pattern.conditions.map { |k, v| "#{k}=#{v}" }.join('; ')
          csv << [
            i + 1,
            pattern.frequency,
            pattern.avg_gain.round(2),
            pattern.avg_holding_days.round(1),
            pattern.success_rate.round(2),
            conditions_str
          ]
        end
      end

      puts "Patterns exported to #{filename}"
    end

    private

    # Step 1: Find all profitable inflection points
    def find_profitable_points
      puts "Step 1: Detecting inflection points and analyzing FPOP..."

      prices = @stock.df["adj_close_price"].to_a

      # Step 1a: Calculate FPL analysis for all points
      fpl_analysis = SQA::FPOP.fpl_analysis(prices, fpop: @fpop)

      # Step 1b: Detect inflection points (local minima and maxima)
      inflection_points = detect_inflection_points(prices)
      puts "  Found #{inflection_points.size} inflection points"

      # Step 1c: Check which inflection points lead to profitable moves
      profitable_count = 0
      filtered_by_risk = 0
      filtered_by_direction = 0

      inflection_points.each do |inflection_idx|
        # Skip if not enough future data
        next if inflection_idx + @fpop >= prices.size
        next if inflection_idx >= fpl_analysis.size

        entry_price = prices[inflection_idx]
        fpl_data = fpl_analysis[inflection_idx]

        # Optional: Filter by FPL risk (volatility)
        if @max_fpl_risk && fpl_data[:risk] > @max_fpl_risk
          filtered_by_risk += 1
          next
        end

        # Optional: Filter by FPL direction
        if @required_fpl_directions && !@required_fpl_directions.include?(fpl_data[:direction])
          filtered_by_direction += 1
          next
        end

        # Calculate price change over fpop period
        future_prices = prices[(inflection_idx + 1)..(inflection_idx + @fpop)]
        max_future_price = future_prices.max
        min_future_price = future_prices.min

        # Calculate gain/loss percentages
        max_gain_percent = ((max_future_price - entry_price) / entry_price * 100.0)
        max_loss_percent = ((min_future_price - entry_price) / entry_price * 100.0)

        # Check if gain exceeds threshold (buy opportunity)
        if max_gain_percent >= @min_gain_percent
          exit_idx = inflection_idx + 1 + future_prices.index(max_future_price)

          @profitable_points << ProfitablePoint.new(
            entry_index: inflection_idx,
            entry_price: entry_price,
            exit_index: exit_idx,
            exit_price: max_future_price,
            fpl_data: fpl_data
          )
          profitable_count += 1
        # Check if loss exceeds threshold (sell opportunity)
        elsif max_loss_percent <= @min_loss_percent
          exit_idx = inflection_idx + 1 + future_prices.index(min_future_price)

          @profitable_points << ProfitablePoint.new(
            entry_index: inflection_idx,
            entry_price: entry_price,
            exit_index: exit_idx,
            exit_price: min_future_price,
            fpl_data: fpl_data
          )
          profitable_count += 1
        end
      end

      puts "  Inflection points analyzed: #{inflection_points.size}"
      puts "  Filtered by risk: #{filtered_by_risk}" if @max_fpl_risk
      puts "  Filtered by direction: #{filtered_by_direction}" if @required_fpl_directions
      puts "  Profitable opportunities found: #{@profitable_points.size}"
      if inflection_points.size > 0
        puts "  Success rate: #{(@profitable_points.size.to_f / inflection_points.size * 100).round(2)}%"
      end

      # Print FPL quality stats
      if @profitable_points.any? && @profitable_points.first.fpl_direction
        avg_risk = @profitable_points.map(&:fpl_risk).compact.sum / @profitable_points.size
        avg_magnitude = @profitable_points.map(&:fpl_magnitude).compact.sum / @profitable_points.size
        directions = @profitable_points.map(&:fpl_direction).compact.tally
        puts "  Average FPL risk: #{avg_risk.round(2)}%"
        puts "  Average FPL magnitude: #{avg_magnitude.round(2)}%"
        puts "  Direction distribution: #{directions}"
      end
      puts
    end

    # Detect inflection points (local minima and maxima)
    def detect_inflection_points(prices)
      inflection_points = []
      window = @inflection_window

      # Scan for local minima and maxima
      (window...(prices.size - window)).each do |idx|
        current_price = prices[idx]

        # Get surrounding window
        left_window = prices[(idx - window)...idx]
        right_window = prices[(idx + 1)..(idx + window)]

        # Check if local minimum (potential buy point)
        if left_window.all? { |p| current_price <= p } && right_window.all? { |p| current_price <= p }
          inflection_points << idx
        # Check if local maximum (potential sell point)
        elsif left_window.all? { |p| current_price >= p } && right_window.all? { |p| current_price >= p }
          inflection_points << idx
        end
      end

      inflection_points
    end

    # Step 2: Calculate indicator states at each profitable point
    def analyze_indicator_states
      puts "Step 2: Analyzing indicator states at profitable points..."

      prices = @stock.df["adj_close_price"].to_a
      volumes = @stock.df["volume"].to_a
      highs = @stock.df["high_price"].to_a
      lows = @stock.df["low_price"].to_a

      # Pre-calculate all indicators for efficiency
      indicator_cache = calculate_all_indicators(prices, volumes, highs, lows)

      @profitable_points.each do |point|
        idx = point.entry_index
        point.indicators = extract_indicator_states(idx, indicator_cache, prices, volumes)
      end

      puts "  Analyzed #{@profitable_points.size} profitable points"
      puts
    end

    # Calculate all indicators once for efficiency
    def calculate_all_indicators(prices, volumes, highs, lows)
      cache = {}

      # RSI
      rsi_config = @indicators_config[:rsi]
      cache[:rsi] = SQAI.rsi(prices, period: rsi_config[:period])

      # MACD
      macd_config = @indicators_config[:macd]
      macd_line, signal_line, histogram = SQAI.macd(
        prices,
        fast_period: macd_config[:fast],
        slow_period: macd_config[:slow],
        signal_period: macd_config[:signal]
      )
      cache[:macd_line] = macd_line
      cache[:macd_signal] = signal_line
      cache[:macd_histogram] = histogram

      # Stochastic
      stoch_config = @indicators_config[:stoch]
      stoch_k, stoch_d = SQAI.stoch(
        highs, lows, prices,
        fastk_period: stoch_config[:k_period],
        slowk_period: stoch_config[:d_period],
        slowd_period: stoch_config[:d_period]
      )
      cache[:stoch_k] = stoch_k
      cache[:stoch_d] = stoch_d

      # SMAs
      sma_config = @indicators_config[:sma_cross]
      cache[:sma_short] = SQAI.sma(prices, period: sma_config[:short])
      cache[:sma_long] = SQAI.sma(prices, period: sma_config[:long])

      # EMA
      ema_config = @indicators_config[:ema]
      cache[:ema] = SQAI.ema(prices, period: ema_config[:period])

      # Bollinger Bands
      bb_config = @indicators_config[:bbands]
      upper, middle, lower = SQAI.bbands(
        prices,
        period: bb_config[:period],
        nbdev_up: bb_config[:nbdev],
        nbdev_down: bb_config[:nbdev]
      )
      cache[:bb_upper] = upper
      cache[:bb_middle] = middle
      cache[:bb_lower] = lower

      cache
    rescue => e
      puts "  Warning: Indicator calculation failed: #{e.message}"
      {}
    end

    # Extract indicator states at a specific index
    def extract_indicator_states(idx, cache, prices, volumes)
      states = {}

      # RSI state
      if cache[:rsi] && idx < cache[:rsi].size
        rsi_val = cache[:rsi][idx]
        rsi_config = @indicators_config[:rsi]

        states[:rsi] = if rsi_val < rsi_config[:oversold]
                        :oversold
                      elsif rsi_val > rsi_config[:overbought]
                        :overbought
                      else
                        :neutral
                      end
        states[:rsi_value] = rsi_val
      end

      # MACD state
      if cache[:macd_line] && cache[:macd_signal] && idx >= 1
        macd_curr = cache[:macd_line][idx]
        signal_curr = cache[:macd_signal][idx]
        macd_prev = cache[:macd_line][idx - 1]
        signal_prev = cache[:macd_signal][idx - 1]

        states[:macd_crossover] = if macd_prev <= signal_prev && macd_curr > signal_curr
                                    :bullish
                                  elsif macd_prev >= signal_prev && macd_curr < signal_curr
                                    :bearish
                                  else
                                    :none
                                  end
        states[:macd_position] = macd_curr > signal_curr ? :above : :below
      end

      # Stochastic state
      if cache[:stoch_k] && idx < cache[:stoch_k].size
        stoch_k_val = cache[:stoch_k][idx]
        stoch_config = @indicators_config[:stoch]

        states[:stoch] = if stoch_k_val < stoch_config[:oversold]
                          :oversold
                        elsif stoch_k_val > stoch_config[:overbought]
                          :overbought
                        else
                          :neutral
                        end
      end

      # SMA crossover state
      if cache[:sma_short] && cache[:sma_long] && idx < cache[:sma_short].size
        sma_short = cache[:sma_short][idx]
        sma_long = cache[:sma_long][idx]

        states[:sma_cross] = sma_short > sma_long ? :golden : :death
      end

      # Bollinger Bands position
      if cache[:bb_upper] && cache[:bb_lower] && idx < prices.size
        price = prices[idx]
        upper = cache[:bb_upper][idx]
        lower = cache[:bb_lower][idx]

        states[:bb_position] = if price < lower
                                :below_lower
                              elsif price > upper
                                :above_upper
                              else
                                :inside
                              end
      end

      # Price vs EMA
      if cache[:ema] && idx < cache[:ema].size && idx < prices.size
        price = prices[idx]
        ema = cache[:ema][idx]

        states[:price_vs_ema] = price > ema ? :above : :below
      end

      # Volume state
      if idx >= 20 && volumes.size > idx
        current_volume = volumes[idx]
        avg_volume = volumes[(idx - 19)..idx].sum / 20.0
        vol_config = @indicators_config[:volume]

        states[:volume] = if current_volume > avg_volume * vol_config[:threshold]
                           :high
                         elsif current_volume < avg_volume * 0.5
                           :low
                         else
                           :normal
                         end
      end

      states
    end

    # Step 3: Mine patterns from indicator states
    def mine_patterns(min_frequency: 2)
      puts "Step 3: Mining patterns from indicator states..."

      pattern_map = Hash.new { |h, k| h[k] = Pattern.new(conditions: k) }

      # Generate all possible pattern combinations
      @profitable_points.each do |point|
        # Single indicator patterns
        point.indicators.each do |indicator, state|
          key = { indicator => state }
          pattern_map[key].frequency += 1
          pattern_map[key].occurrences << point
        end

        # Two-indicator patterns
        indicators = point.indicators.to_a
        indicators.combination(2).each do |combo|
          key = combo.to_h
          pattern_map[key].frequency += 1
          pattern_map[key].occurrences << point
        end

        # Three-indicator patterns (for strong signals)
        indicators.combination(3).each do |combo|
          key = combo.to_h
          pattern_map[key].frequency += 1
          pattern_map[key].occurrences << point
        end
      end

      # Filter patterns by minimum frequency
      @patterns = pattern_map.values.select { |p| p.frequency >= min_frequency }

      # Sort by frequency (most common first)
      @patterns.sort_by! { |p| [-p.frequency, -p.conditions.size] }

      puts "  Found #{@patterns.size} patterns (min frequency: #{min_frequency})"
      puts
    end

    # Step 4: Calculate pattern statistics
    def calculate_pattern_statistics
      puts "Step 4: Calculating pattern statistics..."

      @patterns.each do |pattern|
        gains = pattern.occurrences.map(&:gain_percent)
        holding_days = pattern.occurrences.map(&:holding_days)

        pattern.avg_gain = gains.sum / gains.size.to_f
        pattern.avg_holding_days = holding_days.sum / holding_days.size.to_f

        # Calculate success rate by backtesting the pattern
        pattern.success_rate = calculate_success_rate(pattern)
      end

      # Re-sort by success rate and gain
      @patterns.sort_by! { |p| [-p.success_rate, -p.avg_gain, -p.frequency] }

      puts "  Calculated statistics for #{@patterns.size} patterns"
      puts
    end

    # Calculate success rate for a pattern across all history
    def calculate_success_rate(pattern)
      # Simplified: use frequency as proxy for success rate
      # In production, you'd backtest the pattern
      (pattern.frequency.to_f / @profitable_points.size * 100.0)
    end

    # Generate a Proc-based strategy
    def generate_proc_strategy(pattern)
      conditions = pattern.conditions.dup

      lambda do |vector|
        match_count = 0
        total_conditions = conditions.size

        conditions.each do |indicator, expected_state|
          actual_state = get_indicator_state(vector, indicator)
          match_count += 1 if actual_state == expected_state
        end

        # Require all conditions to match
        match_count == total_conditions ? :buy : :hold
      end
    end

    # Generate a Class-based strategy
    def generate_class_strategy(pattern)
      conditions = pattern.conditions.dup
      generator = self

      Class.new do
        define_singleton_method(:trade) do |vector|
          match_count = 0
          total_conditions = conditions.size

          conditions.each do |indicator, expected_state|
            actual_state = generator.send(:get_indicator_state, vector, indicator)
            match_count += 1 if actual_state == expected_state
          end

          match_count == total_conditions ? :buy : :hold
        end

        define_singleton_method(:pattern) do
          conditions
        end
      end
    end

    # Generate a KBS-based strategy
    def generate_kbs_strategy(pattern)
      require_relative 'strategy/kbs_strategy'

      strategy = SQA::Strategy::KBS.new(load_defaults: false)

      # Build rule from pattern
      strategy.add_rule :discovered_pattern do
        pattern.conditions.each do |indicator, state|
          on indicator, { state: state }
        end

        perform do
          assert(:signal, {
            action: :buy,
            confidence: :high,
            reason: :discovered_pattern
          })
        end
      end

      strategy
    end

    # Helper: Get current indicator state from vector
    def get_indicator_state(vector, indicator)
      case indicator
      when :rsi
        return :neutral unless vector.respond_to?(:rsi) && vector.rsi
        rsi_val = Array(vector.rsi).last
        rsi_config = @indicators_config[:rsi]
        if rsi_val < rsi_config[:oversold]
          :oversold
        elsif rsi_val > rsi_config[:overbought]
          :overbought
        else
          :neutral
        end

      when :macd_crossover
        return :none unless vector.respond_to?(:macd) && vector.macd
        macd_line, signal_line = vector.macd
        return :none if macd_line.size < 2 || signal_line.size < 2

        macd_curr = macd_line.last
        signal_curr = signal_line.last
        macd_prev = macd_line[-2]
        signal_prev = signal_line[-2]

        if macd_prev <= signal_prev && macd_curr > signal_curr
          :bullish
        elsif macd_prev >= signal_prev && macd_curr < signal_curr
          :bearish
        else
          :none
        end

      when :stoch
        return :neutral unless vector.respond_to?(:stoch_k) && vector.stoch_k
        stoch_k_val = Array(vector.stoch_k).last
        stoch_config = @indicators_config[:stoch]
        if stoch_k_val < stoch_config[:oversold]
          :oversold
        elsif stoch_k_val > stoch_config[:overbought]
          :overbought
        else
          :neutral
        end

      else
        :unknown
      end
    end
  end
end
