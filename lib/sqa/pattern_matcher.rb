# lib/sqa/pattern_matcher.rb
# frozen_string_literal: true

module SQA
  ##
  # PatternMatcher - Find similar historical patterns
  #
  # Provides methods for:
  # - Pattern similarity search (nearest-neighbor)
  # - Shape-based pattern matching
  # - Predict future moves based on similar past patterns
  # - Pattern clustering
  #
  # Uses techniques:
  # - Euclidean distance
  # - Dynamic Time Warping (DTW)
  # - Pearson correlation
  #
  # @example Find similar patterns
  #   matcher = SQA::PatternMatcher.new(stock: stock)
  #   similar = matcher.find_similar(lookback: 10, num_matches: 5)
  #   # Returns 5 most similar historical 10-day patterns
  #
  class PatternMatcher
    attr_reader :stock, :prices

    ##
    # Initialize pattern matcher
    #
    # @param stock [SQA::Stock] Stock object
    #
    def initialize(stock:)
      @stock = stock
      @prices = stock.df.data["adj_close_price"].to_a
    end

    ##
    # Find similar historical patterns to current pattern
    #
    # @param lookback [Integer] Pattern length (days)
    # @param num_matches [Integer] Number of similar patterns to find
    # @param method [Symbol] Distance method (:euclidean, :dtw, :correlation)
    # @param normalize [Boolean] Normalize patterns before comparison
    # @return [Array<Hash>] Similar patterns with metadata
    #
    def find_similar(lookback: 10, num_matches: 5, method: :euclidean, normalize: true)
      return [] if @prices.size < lookback * 2

      current_pattern = @prices[-lookback..]
      current_pattern = normalize_pattern(current_pattern) if normalize

      similarities = []

      (@prices.size - lookback - 20).times do |start_idx|
        next if start_idx + lookback >= @prices.size - lookback  # Don't compare to recent data

        candidate = build_similarity_candidate(start_idx, lookback, current_pattern, method, normalize)
        similarities << candidate if candidate
      end

      similarities.sort_by { |s| s[:distance] }.first(num_matches)
    end

    ##
    # Predict future price movement based on similar patterns
    #
    # @param lookback [Integer] Pattern length
    # @param forecast_periods [Integer] Periods to forecast
    # @param num_matches [Integer] Number of similar patterns to use
    # @return [Hash] Forecast with confidence intervals
    #
    def forecast(lookback: 10, forecast_periods: 5, num_matches: 10)
      similar = find_similar(lookback: lookback, num_matches: num_matches)

      return nil if similar.empty?

      # Collect future returns from similar patterns
      future_returns = similar.map { |s| s[:future_return] }

      # Statistical forecast
      mean_return = future_returns.sum / future_returns.size.to_f
      std_return = standard_deviation(future_returns)

      current_price = @prices.last
      forecast_price = current_price * (1 + mean_return)

      {
        forecast_price: forecast_price,
        forecast_return: mean_return,
        confidence_interval_95: [
          current_price * (1 + mean_return - (1.96 * std_return)),
          current_price * (1 + mean_return + (1.96 * std_return))
        ],
        num_matches: similar.size,
        similar_patterns: similar,
        current_price: current_price
      }
    end

    ##
    # Detect chart patterns (head & shoulders, double top, etc.)
    #
    # @param pattern_type [Symbol] Pattern to detect
    # @return [Array<Hash>] Detected patterns
    #
    def detect_chart_pattern(pattern_type)
      case pattern_type
      when :double_top
        detect_double_top
      when :double_bottom
        detect_double_bottom
      when :head_and_shoulders
        detect_head_shoulders
      when :triangle
        detect_triangle
      else
        []
      end
    end

    ##
    # Cluster patterns by similarity
    #
    # @param pattern_length [Integer] Length of patterns
    # @param num_clusters [Integer] Number of clusters
    # @return [Array<Array<Hash>>] Clusters of similar patterns
    #
    def cluster_patterns(pattern_length: 10, num_clusters: 5)
      return [] if @prices.size < pattern_length * num_clusters

      patterns = extract_all_patterns(pattern_length)
      centroids = patterns.sample(num_clusters).map { |p| p[:pattern] }
      clusters = []

      # Simple k-means clustering: iterate until convergence
      10.times do
        clusters = assign_patterns_to_clusters(patterns, centroids, num_clusters)
        centroids = update_cluster_centroids(clusters, centroids, pattern_length)
      end

      clusters.reject(&:empty?)
    end

    ##
    # Calculate pattern strength/quality
    #
    # @param pattern [Array<Float>] Price pattern
    # @return [Hash] Pattern quality metrics
    #
    def pattern_quality(pattern)
      return nil if pattern.size < 3

      # Trend strength (convert to float to avoid integer division)
      first = pattern.first.to_f
      last = pattern.last.to_f
      trend = (last - first) / first

      # Volatility
      returns = pattern.each_cons(2).map { |a, b| (b - a).to_f / a }
      volatility = standard_deviation(returns)

      # Smoothness (how linear is the trend?)
      x_values = (0...pattern.size).to_a
      correlation = pearson_correlation(x_values, pattern)

      {
        trend: trend,
        volatility: volatility,
        smoothness: correlation.abs,
        strength: correlation.abs * (1 - volatility)  # Combined metric
      }
    end

    private

    ##
    # Extract every pattern_length-window pattern from the price series,
    # normalized for clustering plus the raw values for reference.
    #
    def extract_all_patterns(pattern_length)
      patterns = []

      (@prices.size - pattern_length).times do |start_idx|
        pattern = @prices[start_idx, pattern_length]
        patterns << {
          start_index: start_idx,
          pattern: normalize_pattern(pattern),
          raw_pattern: pattern
        }
      end

      patterns
    end

    ##
    # Assign each pattern to its nearest centroid (one k-means iteration step)
    #
    def assign_patterns_to_clusters(patterns, centroids, num_clusters)
      clusters = Array.new(num_clusters) { [] }

      patterns.each do |pattern|
        distances = centroids.map { |centroid| euclidean_distance(pattern[:pattern], centroid) }
        nearest_cluster = distances.index(distances.min)
        clusters[nearest_cluster] << pattern
      end

      clusters
    end

    ##
    # Recompute each cluster's centroid as the average pattern of its
    # members; empty clusters keep their previous centroid.
    #
    def update_cluster_centroids(clusters, previous_centroids, pattern_length)
      clusters.map do |cluster|
        next previous_centroids[0] if cluster.empty?

        pattern_length.times.map do |i|
          cluster.map { |p| p[:pattern][i] }.sum / cluster.size.to_f
        end
      end
    end

    ##
    # Build one similarity-search candidate at start_idx, or nil if there
    # isn't enough future data to measure what happened next.
    #
    def build_similarity_candidate(start_idx, lookback, current_pattern, method, normalize)
      historical_pattern = @prices[start_idx, lookback]
      historical_pattern = normalize_pattern(historical_pattern) if normalize

      distance = distance_between(current_pattern, historical_pattern, method)

      future_start = start_idx + lookback
      future_end = [future_start + lookback, @prices.size - 1].min
      future_prices = @prices[future_start..future_end]

      return nil if future_prices.empty?

      future_return = (future_prices.last - @prices[start_idx + lookback - 1]) /
                      @prices[start_idx + lookback - 1]

      {
        start_index: start_idx,
        end_index: start_idx + lookback - 1,
        distance: distance,
        pattern: historical_pattern,
        future_return: future_return,
        future_prices: future_prices,
        pattern_start_price: @prices[start_idx],
        pattern_end_price: @prices[start_idx + lookback - 1]
      }
    end

    ##
    # Dispatch to the configured distance/similarity method
    #
    def distance_between(pattern_1, pattern_2, method)
      case method
      when :dtw
        dtw_distance(pattern_1, pattern_2)
      when :correlation
        -correlation(pattern_1, pattern_2)  # Negative so lower is better
      else
        # :euclidean and any unrecognized method both fall back to euclidean distance
        euclidean_distance(pattern_1, pattern_2)
      end
    end

    ##
    # Normalize pattern to 0-1 range
    #
    def normalize_pattern(pattern)
      min = pattern.min
      max = pattern.max
      range = max - min

      return pattern if range.zero?

      pattern.map { |p| (p - min) / range }
    end

    ##
    # Euclidean distance between two patterns
    #
    def euclidean_distance(pattern_1, pattern_2)
      return Float::INFINITY if pattern_1.size != pattern_2.size

      sum_squares = pattern_1.zip(pattern_2).sum { |a, b| (a - b)**2 }
      Math.sqrt(sum_squares)
    end

    ##
    # Dynamic Time Warping distance
    #
    # Allows patterns to be stretched in time for better matching.
    #
    def dtw_distance(pattern_1, pattern_2)
      n = pattern_1.size
      m = pattern_2.size

      # Initialize DTW matrix
      dtw = Array.new(n + 1) { Array.new(m + 1, Float::INFINITY) }
      dtw[0][0] = 0

      # Fill matrix
      (1..n).each do |i|
        (1..m).each do |j|
          cost = (pattern_1[i - 1] - pattern_2[j - 1]).abs
          dtw[i][j] = cost + [dtw[i - 1][j], dtw[i][j - 1], dtw[i - 1][j - 1]].min
        end
      end

      dtw[n][m]
    end

    ##
    # Correlation between two patterns
    #
    def correlation(pattern_1, pattern_2)
      pearson_correlation(pattern_1, pattern_2)
    end

    ##
    # Pearson correlation coefficient
    #
    def pearson_correlation(x, y)
      return 0.0 if x.size != y.size || x.size < 2

      n = x.size
      sum_x = x.sum
      sum_y = y.sum
      sum_xy = x.zip(y).sum { |a, b| a * b }
      # rubocop:disable Naming/VariableNumber -- sum_x2/sum_y2 denote Sum(x^2)/Sum(y^2), not "x, item 2"
      sum_x2 = x.sum { |a| a**2 }
      sum_y2 = y.sum { |a| a**2 }

      numerator = (n * sum_xy) - (sum_x * sum_y)
      denominator = Math.sqrt(((n * sum_x2) - (sum_x**2)) * ((n * sum_y2) - (sum_y**2)))
      # rubocop:enable Naming/VariableNumber

      return 0.0 if denominator.zero?

      numerator / denominator
    end

    ##
    # Standard deviation
    #
    def standard_deviation(values)
      return 0.0 if values.empty?

      mean = values.sum / values.size.to_f
      variance = values.map { |v| (v - mean)**2 }.sum / values.size.to_f
      Math.sqrt(variance)
    end

    ##
    # Detect double top pattern
    #
    def detect_double_top
      peaks = find_peaks
      patterns = []

      peaks.each_cons(2) do |peak_1, peak_2|
        next if (peak_2[:index] - peak_1[:index]) > 60  # Too far apart

        # Similar heights?
        price_diff = (peak_1[:price] - peak_2[:price]).abs / peak_1[:price]
        next if price_diff > 0.05  # More than 5% difference

        # Valley between them?
        valley_prices = @prices[(peak_1[:index] + 1)...peak_2[:index]]
        valley_low = valley_prices&.min
        next if valley_low.nil? # adjacent peaks — no valley between them

        # Valley should be significantly lower
        valley_drop = (peak_1[:price] - valley_low) / peak_1[:price]
        next if valley_drop < 0.03  # Less than 3% drop

        patterns << {
          type: :double_top,
          peak1_index: peak_1[:index],
          peak2_index: peak_2[:index],
          peak_price: (peak_1[:price] + peak_2[:price]) / 2.0,
          valley_price: valley_low,
          strength: valley_drop
        }
      end

      patterns
    end

    ##
    # Detect double bottom pattern
    #
    def detect_double_bottom
      valleys = find_valleys
      patterns = []

      valleys.each_cons(2) do |valley_1, valley_2|
        next if (valley_2[:index] - valley_1[:index]) > 60

        price_diff = (valley_1[:price] - valley_2[:price]).abs / valley_1[:price]
        next if price_diff > 0.05

        peak_prices = @prices[(valley_1[:index] + 1)...valley_2[:index]]
        peak_high = peak_prices&.max
        next if peak_high.nil? # adjacent valleys — no peak between them

        peak_rise = (peak_high - valley_1[:price]) / valley_1[:price]
        next if peak_rise < 0.03

        patterns << {
          type: :double_bottom,
          valley1_index: valley_1[:index],
          valley2_index: valley_2[:index],
          valley_price: (valley_1[:price] + valley_2[:price]) / 2.0,
          peak_price: peak_high,
          strength: peak_rise
        }
      end

      patterns
    end

    ##
    # Detect head and shoulders
    #
    def detect_head_shoulders
      peaks = find_peaks
      patterns = []

      peaks.each_cons(3) do |left, head, right|
        # Head should be higher than shoulders
        next unless head[:price] > left[:price] && head[:price] > right[:price]

        # Shoulders should be similar height
        shoulder_diff = (left[:price] - right[:price]).abs / left[:price]
        next if shoulder_diff > 0.05

        patterns << {
          type: :head_and_shoulders,
          left_shoulder: left[:index],
          head: head[:index],
          right_shoulder: right[:index],
          neckline: (left[:price] + right[:price]) / 2.0
        }
      end

      patterns
    end

    ##
    # Detect triangle pattern
    #
    def detect_triangle
      # Simplified: look for converging highs and lows
      recent = @prices.last(60)
      return [] if recent.size < 30

      peaks = find_extrema(recent, :>=)
      valleys = find_extrema(recent, :<=)

      return [] if peaks.size < 2 || valleys.size < 2

      converging_triangle_pattern(peaks, valleys)
    end

    ##
    # Build the triangle pattern result if peaks are trending down and
    # valleys are trending up (converging), otherwise return no patterns.
    #
    def converging_triangle_pattern(peaks, valleys)
      peak_slope = extrema_slope(peaks)
      valley_slope = extrema_slope(valleys)

      return [] unless peak_slope.negative? && valley_slope.positive?

      [{
        type: :symmetrical_triangle,
        apex: peaks.last[:index]
      }]
    end

    ##
    # Slope of price change between the first and last extrema points
    #
    def extrema_slope(points)
      (points.last[:price] - points.first[:price]) / (points.last[:index] - points.first[:index])
    end

    ##
    # Find peaks (local maxima)
    #
    def find_peaks
      find_extrema(@prices, :>=)
    end

    ##
    # Find valleys (local minima)
    #
    def find_valleys
      find_extrema(@prices, :<=)
    end

    ##
    # Shared local-extrema scan used by both find_peaks and find_valleys.
    # A point at index i is an extremum when it satisfies `comparator`
    # (:>= for peaks, :<= for valleys) against every price in its
    # surrounding window on both sides.
    #
    def find_extrema(series, comparator)
      extrema = []
      window = 5

      (window...(series.size - window)).each do |i|
        left = series[(i - window)...i]
        right = series[(i + 1)..(i + window)]
        current = series[i]

        if left.all? { |p| current.send(comparator, p) } && right.all? { |p| current.send(comparator, p) }
          extrema << { index: i, price: current }
        end
      end

      extrema
    end
  end
end
