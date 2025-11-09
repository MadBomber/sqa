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

      # Current pattern (most recent)
      current_pattern = @prices[-lookback..-1]
      current_pattern = normalize_pattern(current_pattern) if normalize

      similarities = []

      # Search through historical data
      (@prices.size - lookback - 20).times do |start_idx|
        next if start_idx + lookback >= @prices.size - lookback  # Don't compare to recent data

        historical_pattern = @prices[start_idx, lookback]
        historical_pattern = normalize_pattern(historical_pattern) if normalize

        distance = case method
                   when :euclidean
                     euclidean_distance(current_pattern, historical_pattern)
                   when :dtw
                     dtw_distance(current_pattern, historical_pattern)
                   when :correlation
                     -correlation(current_pattern, historical_pattern)  # Negative so lower is better
                   else
                     euclidean_distance(current_pattern, historical_pattern)
                   end

        # What happened next?
        future_start = start_idx + lookback
        future_end = [future_start + lookback, @prices.size - 1].min
        future_prices = @prices[future_start..future_end]

        next if future_prices.empty?

        future_return = (future_prices.last - @prices[start_idx + lookback - 1]) /
                        @prices[start_idx + lookback - 1]

        similarities << {
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

      # Sort by distance and return top matches
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
          current_price * (1 + mean_return - 1.96 * std_return),
          current_price * (1 + mean_return + 1.96 * std_return)
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

      # Extract all patterns
      patterns = []
      (@prices.size - pattern_length).times do |start_idx|
        pattern = @prices[start_idx, pattern_length]
        patterns << {
          start_index: start_idx,
          pattern: normalize_pattern(pattern),
          raw_pattern: pattern
        }
      end

      # Simple k-means clustering
      clusters = Array.new(num_clusters) { [] }

      # Initialize centroids randomly
      centroids = patterns.sample(num_clusters).map { |p| p[:pattern] }

      # Iterate until convergence
      10.times do
        # Assign to nearest centroid
        clusters = Array.new(num_clusters) { [] }

        patterns.each do |pattern|
          distances = centroids.map { |centroid| euclidean_distance(pattern[:pattern], centroid) }
          nearest_cluster = distances.index(distances.min)
          clusters[nearest_cluster] << pattern
        end

        # Update centroids
        centroids = clusters.map do |cluster|
          next centroids[0] if cluster.empty?

          # Average pattern
          pattern_length.times.map do |i|
            cluster.map { |p| p[:pattern][i] }.sum / cluster.size.to_f
          end
        end
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

      # Trend strength
      first = pattern.first
      last = pattern.last
      trend = (last - first) / first

      # Volatility
      returns = pattern.each_cons(2).map { |a, b| (b - a) / a }
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
    def euclidean_distance(pattern1, pattern2)
      return Float::INFINITY if pattern1.size != pattern2.size

      sum_squares = pattern1.zip(pattern2).sum { |a, b| (a - b)**2 }
      Math.sqrt(sum_squares)
    end

    ##
    # Dynamic Time Warping distance
    #
    # Allows patterns to be stretched in time for better matching.
    #
    def dtw_distance(pattern1, pattern2)
      n = pattern1.size
      m = pattern2.size

      # Initialize DTW matrix
      dtw = Array.new(n + 1) { Array.new(m + 1, Float::INFINITY) }
      dtw[0][0] = 0

      # Fill matrix
      (1..n).each do |i|
        (1..m).each do |j|
          cost = (pattern1[i - 1] - pattern2[j - 1]).abs
          dtw[i][j] = cost + [dtw[i - 1][j], dtw[i][j - 1], dtw[i - 1][j - 1]].min
        end
      end

      dtw[n][m]
    end

    ##
    # Correlation between two patterns
    #
    def correlation(pattern1, pattern2)
      pearson_correlation(pattern1, pattern2)
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
      sum_x2 = x.sum { |a| a**2 }
      sum_y2 = y.sum { |a| a**2 }

      numerator = (n * sum_xy) - (sum_x * sum_y)
      denominator = Math.sqrt(((n * sum_x2) - sum_x**2) * ((n * sum_y2) - sum_y**2))

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

      peaks.each_cons(2) do |peak1, peak2|
        next if (peak2[:index] - peak1[:index]) > 60  # Too far apart

        # Similar heights?
        price_diff = (peak1[:price] - peak2[:price]).abs / peak1[:price]
        next if price_diff > 0.05  # More than 5% difference

        # Valley between them?
        valley_prices = @prices[(peak1[:index] + 1)...peak2[:index]]
        valley_low = valley_prices.min

        # Valley should be significantly lower
        valley_drop = (peak1[:price] - valley_low) / peak1[:price]
        next if valley_drop < 0.03  # Less than 3% drop

        patterns << {
          type: :double_top,
          peak1_index: peak1[:index],
          peak2_index: peak2[:index],
          peak_price: (peak1[:price] + peak2[:price]) / 2.0,
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

      valleys.each_cons(2) do |valley1, valley2|
        next if (valley2[:index] - valley1[:index]) > 60

        price_diff = (valley1[:price] - valley2[:price]).abs / valley1[:price]
        next if price_diff > 0.05

        peak_prices = @prices[(valley1[:index] + 1)...valley2[:index]]
        peak_high = peak_prices.max

        peak_rise = (peak_high - valley1[:price]) / valley1[:price]
        next if peak_rise < 0.03

        patterns << {
          type: :double_bottom,
          valley1_index: valley1[:index],
          valley2_index: valley2[:index],
          valley_price: (valley1[:price] + valley2[:price]) / 2.0,
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

      peaks = []
      valleys = []

      window = 5
      (window...(recent.size - window)).each do |i|
        left = recent[(i - window)...i]
        right = recent[(i + 1)..(i + window)]

        if left.all? { |p| recent[i] >= p } && right.all? { |p| recent[i] >= p }
          peaks << { index: i, price: recent[i] }
        elsif left.all? { |p| recent[i] <= p } && right.all? { |p| recent[i] <= p }
          valleys << { index: i, price: recent[i] }
        end
      end

      return [] if peaks.size < 2 || valleys.size < 2

      # Check if peaks trending down and valleys trending up
      peak_slope = (peaks.last[:price] - peaks.first[:price]) / (peaks.last[:index] - peaks.first[:index])
      valley_slope = (valleys.last[:price] - valleys.first[:price]) / (valleys.last[:index] - valleys.first[:index])

      if peak_slope < 0 && valley_slope > 0
        [{
          type: :symmetrical_triangle,
          apex: peaks.last[:index]
        }]
      else
        []
      end
    end

    ##
    # Find peaks (local maxima)
    #
    def find_peaks
      peaks = []
      window = 5

      (window...(@ prices.size - window)).each do |i|
        left = @prices[(i - window)...i]
        right = @prices[(i + 1)..(i + window)]

        if left.all? { |p| @prices[i] >= p } && right.all? { |p| @prices[i] >= p }
          peaks << { index: i, price: @prices[i] }
        end
      end

      peaks
    end

    ##
    # Find valleys (local minima)
    #
    def find_valleys
      valleys = []
      window = 5

      (window...(@prices.size - window)).each do |i|
        left = @prices[(i - window)...i]
        right = @prices[(i + 1)..(i + window)]

        if left.all? { |p| @prices[i] <= p } && right.all? { |p| @prices[i] <= p }
          valleys << { index: i, price: @prices[i] }
        end
      end

      valleys
    end
  end
end
