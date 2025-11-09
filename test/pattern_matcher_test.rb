# test/pattern_matcher_test.rb
# frozen_string_literal: true

require_relative 'test_helper'

class PatternMatcherTest < Minitest::Test
  def setup
    skip "Skipping integration test - set RUN_INTEGRATION_TESTS=1 to run" unless ENV['RUN_INTEGRATION_TESTS']

    @stock = SQA::Stock.new(ticker: 'AAPL')
    @matcher = SQA::PatternMatcher.new(stock: @stock)
  end

  def test_initialization
    assert_instance_of SQA::PatternMatcher, @matcher
    assert_instance_of Array, @matcher.prices
    assert @matcher.prices.size > 0
  end

  def test_find_similar_euclidean
    similar = @matcher.find_similar(lookback: 10, num_matches: 5, method: :euclidean)

    assert_instance_of Array, similar
    assert similar.size <= 5

    similar.each do |match|
      assert match.key?(:start_index)
      assert match.key?(:distance)
      assert match.key?(:future_return)
      assert match.key?(:pattern)

      assert match[:distance] >= 0
    end

    # Should be sorted by distance (most similar first)
    distances = similar.map { |m| m[:distance] }
    assert_equal distances.sort, distances
  end

  def test_find_similar_dtw
    similar = @matcher.find_similar(lookback: 10, num_matches: 3, method: :dtw)

    assert_instance_of Array, similar
    assert similar.size <= 3
  end

  def test_find_similar_correlation
    similar = @matcher.find_similar(lookback: 10, num_matches: 3, method: :correlation)

    assert_instance_of Array, similar
    assert similar.size <= 3
  end

  def test_forecast
    forecast = @matcher.forecast(lookback: 10, forecast_periods: 5, num_matches: 5)

    assert_instance_of Hash, forecast
    assert forecast.key?(:forecast_price)
    assert forecast.key?(:forecast_return)
    assert forecast.key?(:confidence_interval_95)
    assert forecast.key?(:num_matches)
    assert forecast.key?(:current_price)

    assert forecast[:forecast_price] > 0
    assert_instance_of Array, forecast[:confidence_interval_95]
    assert_equal 2, forecast[:confidence_interval_95].size

    # Confidence interval should be ordered
    lower, upper = forecast[:confidence_interval_95]
    assert lower < upper
  end

  def test_detect_double_top
    patterns = @matcher.detect_chart_pattern(:double_top)

    assert_instance_of Array, patterns

    patterns.each do |pattern|
      assert_equal :double_top, pattern[:type]
      assert pattern.key?(:peak1_index)
      assert pattern.key?(:peak2_index)
      assert pattern.key?(:peak_price)
      assert pattern.key?(:valley_price)
    end
  end

  def test_detect_double_bottom
    patterns = @matcher.detect_chart_pattern(:double_bottom)

    assert_instance_of Array, patterns

    patterns.each do |pattern|
      assert_equal :double_bottom, pattern[:type]
      assert pattern.key?(:valley1_index)
      assert pattern.key?(:valley2_index)
    end
  end

  def test_detect_head_and_shoulders
    patterns = @matcher.detect_chart_pattern(:head_and_shoulders)

    assert_instance_of Array, patterns

    patterns.each do |pattern|
      assert_equal :head_and_shoulders, pattern[:type]
      assert pattern.key?(:left_shoulder)
      assert pattern.key?(:head)
      assert pattern.key?(:right_shoulder)
      assert pattern.key?(:neckline)
    end
  end

  def test_detect_triangle
    patterns = @matcher.detect_chart_pattern(:triangle)

    assert_instance_of Array, patterns
  end

  def test_cluster_patterns
    clusters = @matcher.cluster_patterns(pattern_length: 10, num_clusters: 3)

    assert_instance_of Array, clusters
    assert clusters.size <= 3

    clusters.each do |cluster|
      assert_instance_of Array, cluster
      cluster.each do |pattern|
        assert pattern.key?(:start_index)
        assert pattern.key?(:pattern)
      end
    end
  end

  def test_pattern_quality
    pattern = @matcher.prices.first(20)
    quality = @matcher.pattern_quality(pattern)

    assert_instance_of Hash, quality
    assert quality.key?(:trend)
    assert quality.key?(:volatility)
    assert quality.key?(:smoothness)
    assert quality.key?(:strength)

    assert quality[:volatility] >= 0
    assert quality[:smoothness] >= -1 && quality[:smoothness] <= 1
  end
end

# Unit tests that don't require stock data
class PatternMatcherUnitTest < Minitest::Test
  def setup
    # Create mock stock
    prices = (0...100).map { |i| 100 + 10 * Math.sin(i / 10.0) + rand(-2.0..2.0) }

    mock_df = Minitest::Mock.new
    mock_data = Minitest::Mock.new
    mock_data.expect(:[], prices, ["adj_close_price"])
    mock_df.expect(:data, mock_data)

    @stock = Minitest::Mock.new
    @stock.expect(:df, mock_df)

    @matcher = SQA::PatternMatcher.new(stock: @stock)
  end

  def test_find_similar_with_mock_data
    similar = @matcher.find_similar(lookback: 5, num_matches: 2)

    assert_instance_of Array, similar
  end

  def test_pattern_quality_with_uptrend
    uptrend = [100, 102, 104, 106, 108, 110]
    quality = @matcher.pattern_quality(uptrend)

    assert quality[:trend] > 0, "Uptrend should have positive trend"
    assert quality[:smoothness] > 0.9, "Linear uptrend should be smooth"
  end

  def test_pattern_quality_with_downtrend
    downtrend = [110, 108, 106, 104, 102, 100]
    quality = @matcher.pattern_quality(downtrend)

    assert quality[:trend] < 0, "Downtrend should have negative trend"
  end
end
