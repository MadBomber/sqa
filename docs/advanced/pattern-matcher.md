# Pattern Matcher

Pattern recognition and similarity search for forecasting.

## Find Similar Patterns

```ruby
matcher = SQA::PatternMatcher.new(stock: stock)

# Find historical patterns similar to current
similar = matcher.find_similar(
  lookback: 10,           # 10-period pattern
  num_matches: 5,          # Find 5 best matches
  method: :euclidean      # Distance metric
)

similar.each do |match|
  puts "Distance: #{match[:distance]}"
  puts "Future return: #{match[:future_return]}%"
end
```

## Distance Methods

- `:euclidean` - Standard distance
- `:dtw` - Dynamic Time Warping (handles compression/stretching)
- `:correlation` - Correlation-based similarity

## Forecasting

```ruby
forecast = matcher.forecast(
  lookback: 10,
  forecast_periods: 5,
  method: :dtw
)

puts "Forecast price: #{forecast[:forecast_price]}"
puts "Expected return: #{forecast[:forecast_return]}%"
puts "95% CI: #{forecast[:confidence_interval_95]}"
```

## Chart Pattern Detection

```ruby
# Detect double top/bottom
patterns = matcher.detect_chart_pattern(:double_top)

# Detect head & shoulders
patterns = matcher.detect_chart_pattern(:head_and_shoulders)

# Detect triangles
patterns = matcher.detect_chart_pattern(:triangle)

patterns.each do |pattern|
  puts "#{pattern[:type]} at index #{pattern[:index]}"
  puts "Confidence: #{pattern[:confidence]}"
end
```

## Pattern Clustering

```ruby
# Group similar patterns
clusters = matcher.cluster_patterns(
  num_clusters: 5,
  lookback: 10
)

clusters.each_with_index do |cluster, i|
  puts "Cluster #{i}: #{cluster.size} patterns"
  puts "  Avg future return: #{cluster[:avg_return]}%"
end
```

