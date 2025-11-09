# Ensemble Strategies

Combine multiple strategies with voting and meta-learning.

## Basic Ensemble

```ruby
ensemble = SQA::Ensemble.new(
  strategies: [
    SQA::Strategy::RSI,
    SQA::Strategy::MACD,
    SQA::Strategy::BollingerBands
  ],
  voting_method: :majority
)

signal = ensemble.signal(vector)  # => :buy, :sell, or :hold
```

## Voting Methods

### Majority Voting
```ruby
voting_method: :majority  # Most common signal wins
```

### Weighted Voting
```ruby
voting_method: :weighted
# Weight strategies by past performance
```

### Unanimous
```ruby
voting_method: :unanimous  # All must agree
```

### Confidence-Based
```ruby
voting_method: :confidence  # Weight by confidence scores
```

## Dynamic Weighting

```ruby
# Update weights based on performance
ensemble.update_weight(SQA::Strategy::RSI, 1.5)   # Increase weight
ensemble.update_weight(SQA::Strategy::MACD, 0.5)  # Decrease weight
```

## Strategy Rotation

```ruby
# Select best strategy for current market
selected = ensemble.rotate(stock)
# Automatically switches based on recent performance
```

## Backtest Comparison

```ruby
comparison = ensemble.backtest_comparison(stock)

comparison.each do |name, results|
  puts "#{name}: Return = #{results[:return]}%"
end
```

