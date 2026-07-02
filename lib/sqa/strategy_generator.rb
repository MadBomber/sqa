# frozen_string_literal: true

#
# Strategy Generator - Reverse Engineering Profitable Trades
#
# This module analyzes historical price data to identify inflection points (turning points)
# that precede significant price movements. It discovers which indicator patterns were
# present at those inflection points.
#
# FPOP (Future Period of Performance): The number of days to look ahead from an
# inflection point to measure if the price change exceeds the threshold.
#
# Process:
# 1. Detect inflection points (local minima for buys, local maxima for sells)
# 2. Check if price change during fpop period exceeds threshold percentage
# 3. Calculate all indicators at those profitable inflection points
# 4. Identify which indicators were "active" (in buy/sell zones)
# 5. Find common patterns across profitable trades
# 6. Generate trading rules from discovered patterns
# 7. Optionally create KBS rules or strategy classes
#
# Example:
#   generator = SQA::StrategyGenerator.new(
#     stock: stock,
#     min_gain_percent: 10.0,
#     fpop: 10  # Future Period of Performance (days)
#   )
#
#   patterns = generator.discover_patterns
#   strategy = generator.generate_strategy
#

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
        return unless fpl_data
        @fpl_min_delta = fpl_data[:min_delta]
        @fpl_max_delta = fpl_data[:max_delta]
        @fpl_risk = fpl_data[:risk]
        @fpl_direction = fpl_data[:direction]
        @fpl_magnitude = fpl_data[:magnitude]
      end

      def to_s
        fpl_info = fpl_direction ? " dir=#{fpl_direction} risk=#{fpl_risk.round(2)}%" : ""
        "ProfitablePoint(gain=#{gain_percent.round(2)}%, days=#{holding_days}, entry=#{entry_index}#{fpl_info})"
      end
    end

    # Represents a discovered indicator pattern
    class Pattern
      attr_accessor :conditions, :frequency, :avg_gain, :avg_holding_days,
                    :success_rate, :occurrences,
                    :context

      def initialize(conditions: {})
        @conditions = conditions
        @frequency = 0
        @avg_gain = 0.0
        @avg_holding_days = 0.0
        @success_rate = 0.0
        @occurrences = []
        @context = PatternContext.new
      end

      def to_s
        ctx_info = @context.valid? ? " [#{@context.summary}]" : ""
        "Pattern(conditions=#{conditions.size}, freq=#{frequency}, gain=#{avg_gain.round(2)}%, " \
          "success=#{success_rate.round(2)}%#{ctx_info})"
      end
    end

    # Pattern Context - metadata about when/where pattern is valid
    class PatternContext
      attr_accessor :market_regime, :valid_months, :valid_quarters,
                    :discovered_period, :validation_period,
                    :stability_score, :sector, :volatility_regime

      def initialize
        @market_regime = nil        # :bull, :bear, :sideways
        @valid_months = []          # [10, 11, 12, 1] for Q4/Q1
        @valid_quarters = []        # [1, 4] for Q1/Q4
        @discovered_period = nil    # "2020-01-01 to 2022-12-31"
        @validation_period = nil    # "2023-01-01 to 2024-11-08"
        @stability_score = nil      # 0.0-1.0, how consistent over time
        @sector = nil               # :technology, :finance, etc.
        @volatility_regime = nil    # :low, :medium, :high
      end

      def valid?
        @market_regime || @valid_months.any? || @sector
      end

      def summary
        parts = []
        parts << @market_regime.to_s if @market_regime
        parts << "months:#{@valid_months.join(',')}" if @valid_months.any?
        parts << "Q#{@valid_quarters.join(',')}" if @valid_quarters.any?
        parts << @sector.to_s if @sector
        parts.join(' ')
      end

      # Check if pattern is valid for given date and conditions
      def valid_for?(date: nil, regime: nil, sector: nil)
        # Check market regime
        return false if @market_regime && regime && @market_regime != regime

        # Check sector
        return false if @sector && sector && @sector != sector

        # Check calendar constraints
        if date
          return false if @valid_months.any? && !@valid_months.include?(date.month)

          quarter = ((date.month - 1) / 3) + 1
          return false if @valid_quarters.any? && !@valid_quarters.include?(quarter)
        end

        true
      end
    end

    attr_reader :stock, :profitable_points, :patterns, :min_gain_percent,
                :fpop, :min_loss_percent, :indicators_config, :inflection_window,
                :max_fpl_risk, :required_fpl_directions

    def initialize(stock:, min_gain_percent: 10.0, min_loss_percent: nil, fpop: 10, inflection_window: 3, max_fpl_risk: nil,
                   required_fpl_directions: nil)
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
      @patterns.take(top_n).map.with_index do |_pattern, i|
        generate_strategy(pattern_index: i, strategy_type: strategy_type)
      end
    end

    # Print discovered patterns
    def print_patterns(max_patterns: 10)
      puts "\n" + ("=" * 70)
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

    # Walk-forward validation - discover patterns with time-series cross-validation
    #
    # Splits data into train/test windows and rolls forward through history
    # to prevent overfitting. Only keeps patterns that work out-of-sample.
    #
    # @param train_size [Integer] Training window size in days
    # @param test_size [Integer] Testing window size in days
    # @param step_size [Integer] How many days to step forward each iteration
    # @return [Hash] Validation results with patterns and performance
    #
    def walk_forward_validate(train_size: 250, test_size: 60, step_size: 30)
      print_walk_forward_header(train_size, test_size, step_size)

      prices = @stock.df["adj_close_price"].to_a
      dates = walk_forward_dates

      validated_patterns = []
      validation_results = []

      start_idx = 0
      iteration = 0

      while start_idx + train_size + test_size < prices.size
        iteration += 1
        window = walk_forward_window(start_idx, train_size, test_size)

        print_walk_forward_iteration(iteration, window, dates)

        run_walk_forward_iteration(window, iteration, dates, validated_patterns, validation_results)

        start_idx += step_size
      end

      print_walk_forward_summary(iteration, validation_results, validated_patterns)

      {
        validated_patterns: validated_patterns,
        validation_results: validation_results,
        total_iterations: iteration
      }
    end

    # Print the walk-forward validation configuration header
    def print_walk_forward_header(train_size, test_size, step_size)
      puts "\n" + ("=" * 70)
      puts "Walk-Forward Validation"
      puts "=" * 70
      puts "Training window: #{train_size} days"
      puts "Testing window: #{test_size} days"
      puts "Step size: #{step_size} days"
      puts
    end

    # Parsed dates aligned with the stock's price array
    def walk_forward_dates
      date_column = @stock.df.data.columns.include?("date") ? "date" : "timestamp"
      @stock.df[date_column].to_a.map { |d| Date.parse(d.to_s) }
    end

    # Compute the train/test index boundaries for one iteration
    def walk_forward_window(start_idx, train_size, test_size)
      train_start = start_idx
      train_end = start_idx + train_size
      test_start = train_end
      test_end = test_start + test_size

      { train_start: train_start, train_end: train_end, test_start: test_start, test_end: test_end }
    end

    def print_walk_forward_iteration(iteration, window, dates)
      puts "\nIteration #{iteration}:"
      puts "  Train: #{dates[window[:train_start]]} to #{dates[window[:train_end] - 1]}"
      puts "  Test:  #{dates[window[:test_start]]} to #{dates[window[:test_end] - 1]}"
    end

    # Discover patterns on the training window, then validate each pattern
    # against the out-of-sample test window, accumulating results in place.
    def run_walk_forward_iteration(window, iteration, dates, validated_patterns, validation_results)
      train_data = create_stock_subset(window[:train_start], window[:train_end])

      temp_generator = SQA::StrategyGenerator.new(
        stock: train_data,
        min_gain_percent: @min_gain_percent,
        fpop: @fpop,
        inflection_window: @inflection_window,
        max_fpl_risk: @max_fpl_risk,
        required_fpl_directions: @required_fpl_directions
      )

      train_patterns = temp_generator.discover_patterns(min_pattern_frequency: 2)
      test_data = create_stock_subset(window[:test_start], window[:test_end])

      train_patterns.each do |pattern|
        validate_pattern_out_of_sample(
          pattern, train_patterns, temp_generator, test_data,
          iteration, window, dates, validated_patterns, validation_results
        )
      end
    end

    # Backtest a single discovered pattern on the out-of-sample test window
    # and record the result; keep the pattern if it performed well.
    def validate_pattern_out_of_sample(pattern, train_patterns, temp_generator, test_data,
                                       iteration, window, dates, validated_patterns, validation_results)
      strategy = temp_generator.generate_strategy(
        pattern_index: train_patterns.index(pattern),
        strategy_type: :proc
      )

      backtest = SQA::Backtest.new(stock: test_data, strategy: strategy)
      results = backtest.run

      validation_results << {
        iteration: iteration,
        pattern: pattern,
        train_period: "#{dates[window[:train_start]]} to #{dates[window[:train_end] - 1]}",
        test_period: "#{dates[window[:test_start]]} to #{dates[window[:test_end] - 1]}",
        test_return: results.total_return,
        test_sharpe: results.sharpe_ratio,
        test_max_drawdown: results.max_drawdown
      }

      if results.total_return.positive? && results.sharpe_ratio > 0.5
        validated_patterns << pattern
      end
    rescue => e
      puts "    Warning: Pattern validation failed: #{e.message}"
    end

    def print_walk_forward_summary(iteration, validation_results, validated_patterns)
      puts "\n" + ("=" * 70)
      puts "Validation Complete"
      puts "  Total iterations: #{iteration}"
      puts "  Total patterns tested: #{validation_results.size}"
      puts "  Patterns validated: #{validated_patterns.size}"
      puts "=" * 70
    end

    # Discover patterns with context (regime, seasonal, sector)
    #
    # @param analyze_regime [Boolean] Detect and filter by market regime
    # @param analyze_seasonal [Boolean] Detect seasonal patterns
    # @param sector [Symbol] Sector classification
    # @return [Array<Pattern>] Patterns with context metadata
    #
    def discover_context_aware_patterns(analyze_regime: true, analyze_seasonal: true, sector: nil)
      puts "\n" + ("=" * 70)
      puts "Context-Aware Pattern Discovery"
      puts "=" * 70

      regime_data = analyze_regime ? detect_and_print_regime : nil
      seasonal_data = analyze_seasonal ? analyze_and_print_seasonality : nil

      patterns = discover_patterns

      patterns.each do |pattern|
        tag_pattern_context(pattern, regime_data, seasonal_data, sector)
      end

      print_context_aware_summary(patterns)

      patterns
    end

    # Step 1: Detect market regime and print regime/period summary
    def detect_and_print_regime
      regime_data = SQA::MarketRegime.detect(@stock)
      puts "Current regime: #{regime_data[:type]} (#{regime_data[:strength]} strength)"

      regime_splits = SQA::MarketRegime.split_by_regime(@stock)

      puts "\nRegime periods:"
      regime_splits.each do |regime, periods|
        total_days = periods.sum { |p| p[:duration] }
        puts "  #{regime}: #{total_days} days across #{periods.size} periods"
      end

      regime_data
    end

    # Step 2: Analyze seasonality and print summary
    def analyze_and_print_seasonality
      seasonal_data = SQA::SeasonalAnalyzer.analyze(@stock)
      puts "\nSeasonal analysis:"
      puts "  Best months: #{seasonal_data[:best_months].join(', ')}"
      puts "  Worst months: #{seasonal_data[:worst_months].join(', ')}"
      puts "  Best quarters: Q#{seasonal_data[:best_quarters].join(', Q')}"
      puts "  Has seasonal pattern: #{seasonal_data[:has_seasonal_pattern]}"

      seasonal_data
    end

    # Step 4: Tag a single pattern with regime/seasonal/sector/discovery-period context
    def tag_pattern_context(pattern, regime_data, seasonal_data, sector)
      if regime_data
        pattern.context.market_regime = regime_data[:type]
        pattern.context.volatility_regime = regime_data[:volatility]
      end

      if seasonal_data && seasonal_data[:has_seasonal_pattern]
        pattern.context.valid_months = seasonal_data[:best_months]
        pattern.context.valid_quarters = seasonal_data[:best_quarters]
      end

      pattern.context.sector = sector if sector

      date_column = @stock.df.data.columns.include?("date") ? "date" : "timestamp"
      dates = @stock.df[date_column].to_a
      pattern.context.discovered_period = "#{dates.first} to #{dates.last}"
    end

    def print_context_aware_summary(patterns)
      puts "\n" + ("=" * 70)
      puts "Context-Aware Discovery Complete"
      puts "  Patterns found: #{patterns.size}"
      puts "  Patterns with context: #{patterns.count { |p| p.context.valid? }}"
      puts "=" * 70
    end

    private

    # Step 1: Find all profitable inflection points
    def find_profitable_points
      puts "Step 1: Detecting inflection points and analyzing FPOP..."

      prices = @stock.df["adj_close_price"].to_a
      fpl_analysis = SQA::FPOP.fpl_analysis(prices, fpop: @fpop)
      inflection_points = detect_inflection_points(prices)
      puts "  Found #{inflection_points.size} inflection points"

      filter_counts = scan_inflection_points_for_profit(inflection_points, prices, fpl_analysis)

      print_profitable_points_summary(inflection_points, filter_counts)
    end

    # Scan every inflection point, skipping/filtering as configured, and
    # append a ProfitablePoint for each one that clears the gain/loss bar.
    # Returns a hash of filter counters used for the summary report.
    def scan_inflection_points_for_profit(inflection_points, prices, fpl_analysis)
      filter_counts = { risk: 0, direction: 0 }

      inflection_points.each do |inflection_idx|
        next if inflection_idx + @fpop >= prices.size
        next if inflection_idx >= fpl_analysis.size

        fpl_data = fpl_analysis[inflection_idx]
        next if filtered_by_fpl_risk?(fpl_data, filter_counts)
        next if filtered_by_fpl_direction?(fpl_data, filter_counts)

        record_profitable_point_if_any(inflection_idx, prices, fpl_data)
      end

      filter_counts
    end

    # Optional: Filter by FPL risk (volatility)
    def filtered_by_fpl_risk?(fpl_data, filter_counts)
      return false unless @max_fpl_risk && fpl_data[:risk] > @max_fpl_risk

      filter_counts[:risk] += 1
      true
    end

    # Optional: Filter by FPL direction
    def filtered_by_fpl_direction?(fpl_data, filter_counts)
      return false unless @required_fpl_directions && !@required_fpl_directions.include?(fpl_data[:direction])

      filter_counts[:direction] += 1
      true
    end

    # Evaluate the future price window for one inflection point and record
    # a ProfitablePoint if either the gain or loss threshold is cleared.
    def record_profitable_point_if_any(inflection_idx, prices, fpl_data)
      entry_price = prices[inflection_idx]
      future_prices = prices[(inflection_idx + 1)..(inflection_idx + @fpop)]
      max_future_price = future_prices.max
      min_future_price = future_prices.min

      max_gain_percent = ((max_future_price - entry_price) / entry_price * 100.0)
      max_loss_percent = ((min_future_price - entry_price) / entry_price * 100.0)

      if max_gain_percent >= @min_gain_percent
        exit_idx = inflection_idx + 1 + future_prices.index(max_future_price)
        append_profitable_point(inflection_idx, entry_price, exit_idx, max_future_price, fpl_data)
      elsif max_loss_percent <= @min_loss_percent
        exit_idx = inflection_idx + 1 + future_prices.index(min_future_price)
        append_profitable_point(inflection_idx, entry_price, exit_idx, min_future_price, fpl_data)
      end
    end

    # Build and store a ProfitablePoint from entry/exit data
    def append_profitable_point(entry_index, entry_price, exit_index, exit_price, fpl_data)
      @profitable_points << ProfitablePoint.new(
        entry_index: entry_index,
        entry_price: entry_price,
        exit_index: exit_index,
        exit_price: exit_price,
        fpl_data: fpl_data
      )
    end

    # Print the Step 1 summary report (counts, success rate, FPL quality stats)
    def print_profitable_points_summary(inflection_points, filter_counts)
      puts "  Inflection points analyzed: #{inflection_points.size}"
      puts "  Filtered by risk: #{filter_counts[:risk]}" if @max_fpl_risk
      puts "  Filtered by direction: #{filter_counts[:direction]}" if @required_fpl_directions
      puts "  Profitable opportunities found: #{@profitable_points.size}"
      if inflection_points.size.positive?
        puts "  Success rate: #{(@profitable_points.size.to_f / inflection_points.size * 100).round(2)}%"
      end

      print_fpl_quality_stats

      puts
    end

    # Print average FPL risk/magnitude and direction distribution, when available
    def print_fpl_quality_stats
      return unless @profitable_points.any? && @profitable_points.first.fpl_direction

      avg_risk = @profitable_points.map(&:fpl_risk).compact.sum / @profitable_points.size
      avg_magnitude = @profitable_points.map(&:fpl_magnitude).compact.sum / @profitable_points.size
      directions = @profitable_points.map(&:fpl_direction).compact.tally
      puts "  Average FPL risk: #{avg_risk.round(2)}%"
      puts "  Average FPL magnitude: #{avg_magnitude.round(2)}%"
      puts "  Direction distribution: #{directions}"
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

        # Local minimum (potential buy point) or local maximum (potential sell point)
        local_min = left_window.all? { |p| current_price <= p } && right_window.all? { |p| current_price <= p }
        local_max = left_window.all? { |p| current_price >= p } && right_window.all? { |p| current_price >= p }
        inflection_points << idx if local_min || local_max
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

      cache_rsi!(cache, prices)
      cache_macd!(cache, prices)
      cache_stoch!(cache, highs, lows, prices)
      cache_smas!(cache, prices)
      cache_ema!(cache, prices)
      cache_bbands!(cache, prices)

      cache
    rescue => e
      puts "  Warning: Indicator calculation failed: #{e.message}"
      {}
    end

    def cache_rsi!(cache, prices)
      rsi_config = @indicators_config[:rsi]
      cache[:rsi] = SQAI.rsi(prices, period: rsi_config[:period])
    end

    def cache_macd!(cache, prices)
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
    end

    def cache_stoch!(cache, highs, lows, prices)
      stoch_config = @indicators_config[:stoch]
      stoch_k, stoch_d = SQAI.stoch(
        highs, lows, prices,
        fastk_period: stoch_config[:k_period],
        slowk_period: stoch_config[:d_period],
        slowd_period: stoch_config[:d_period]
      )
      cache[:stoch_k] = stoch_k
      cache[:stoch_d] = stoch_d
    end

    def cache_smas!(cache, prices)
      sma_config = @indicators_config[:sma_cross]
      cache[:sma_short] = SQAI.sma(prices, period: sma_config[:short])
      cache[:sma_long] = SQAI.sma(prices, period: sma_config[:long])
    end

    def cache_ema!(cache, prices)
      ema_config = @indicators_config[:ema]
      cache[:ema] = SQAI.ema(prices, period: ema_config[:period])
    end

    def cache_bbands!(cache, prices)
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
    end

    # Extract indicator states at a specific index
    def extract_indicator_states(idx, cache, prices, volumes)
      states = {}

      extract_rsi_state(states, idx, cache)
      extract_macd_state(states, idx, cache)
      extract_stoch_state(states, idx, cache)
      extract_sma_cross_state(states, idx, cache)
      extract_bb_position_state(states, idx, cache, prices)
      extract_price_vs_ema_state(states, idx, cache, prices)
      extract_volume_state(states, idx, volumes)

      states
    end

    # RSI state at idx
    def extract_rsi_state(states, idx, cache)
      return unless cache[:rsi] && idx < cache[:rsi].size

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

    # MACD crossover/position state at idx
    def extract_macd_state(states, idx, cache)
      return unless cache[:macd_line] && cache[:macd_signal] && idx >= 1

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

    # Stochastic state at idx
    def extract_stoch_state(states, idx, cache)
      return unless cache[:stoch_k] && idx < cache[:stoch_k].size

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

    # SMA crossover state at idx
    def extract_sma_cross_state(states, idx, cache)
      return unless cache[:sma_short] && cache[:sma_long] && idx < cache[:sma_short].size

      sma_short = cache[:sma_short][idx]
      sma_long = cache[:sma_long][idx]

      states[:sma_cross] = sma_short > sma_long ? :golden : :death
    end

    # Bollinger Bands position state at idx
    def extract_bb_position_state(states, idx, cache, prices)
      return unless cache[:bb_upper] && cache[:bb_lower] && idx < prices.size

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

    # Price vs EMA state at idx
    def extract_price_vs_ema_state(states, idx, cache, prices)
      return unless cache[:ema] && idx < cache[:ema].size && idx < prices.size

      price = prices[idx]
      ema = cache[:ema][idx]

      states[:price_vs_ema] = price > ema ? :above : :below
    end

    # Volume state at idx
    def extract_volume_state(states, idx, volumes)
      return unless idx >= 20 && volumes.size > idx

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

    # Step 3: Mine patterns from indicator states
    def mine_patterns(min_frequency: 2)
      puts "Step 3: Mining patterns from indicator states..."

      pattern_map = Hash.new { |h, k| h[k] = Pattern.new(conditions: k) }

      @profitable_points.each do |point|
        record_pattern_combinations(pattern_map, point)
      end

      @patterns = pattern_map.values.select { |p| p.frequency >= min_frequency }
      @patterns.sort_by! { |p| [-p.frequency, -p.conditions.size] }

      puts "  Found #{@patterns.size} patterns (min frequency: #{min_frequency})"
      puts
    end

    # Record single-, two-, and three-indicator pattern combinations for one point
    def record_pattern_combinations(pattern_map, point)
      indicators = point.indicators.to_a

      point.indicators.each do |indicator, state|
        record_pattern_occurrence(pattern_map, { indicator => state }, point)
      end

      indicators.combination(2).each do |combo|
        record_pattern_occurrence(pattern_map, combo.to_h, point)
      end

      indicators.combination(3).each do |combo|
        record_pattern_occurrence(pattern_map, combo.to_h, point)
      end
    end

    # Increment frequency and track the occurrence for one pattern key
    def record_pattern_occurrence(pattern_map, key, point)
      pattern_map[key].frequency += 1
      pattern_map[key].occurrences << point
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

    # Helper: Create stock subset for walk-forward validation
    def create_stock_subset(start_idx, end_idx)
      # Extract subset of data
      subset_df_data = {}

      @stock.df.columns.each do |col|
        subset_df_data[col] = @stock.df[col].to_a[start_idx...end_idx]
      end

      # Create new stock object with subset
      temp_stock = SQA::Stock.allocate
      temp_stock.instance_variable_set(:@ticker, @stock.ticker)
      temp_stock.instance_variable_set(:@df, SQA::DataFrame.new(subset_df_data))

      temp_stock
    end

    # Helper: Get current indicator state from vector
    def get_indicator_state(vector, indicator)
      case indicator
      when :rsi then indicator_state_rsi(vector)
      when :macd_crossover then indicator_state_macd_crossover(vector)
      when :stoch then indicator_state_stoch(vector)
      else :unknown
      end
    end

    def indicator_state_rsi(vector)
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
    end

    def indicator_state_macd_crossover(vector)
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
    end

    def indicator_state_stoch(vector)
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
    end
  end
end
