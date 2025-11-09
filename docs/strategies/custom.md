# Creating Custom Strategies

## Overview

Learn how to create your own trading strategies in the SQA framework.

## Strategy Interface

All strategies must implement a `self.trade(vector)` class method that returns `:buy`, `:sell`, or `:hold`.

## Basic Template

```ruby
# lib/sqa/strategy/my_strategy.rb

class SQA::Strategy::MyStrategy
  def self.trade(vector)
    # 1. Validate input
    return :hold unless vector.respond_to?(:prices)
    return :hold if vector.prices.nil? || vector.prices.size < 20

    # 2. Extract data
    prices = vector.prices
    
    # 3. Calculate indicators
    sma = SQAI.sma(prices, period: 20)
    rsi = SQAI.rsi(prices, period: 14)
    
    # 4. Implement trading logic
    if rsi.last < 30 && prices.last > sma.last
      :buy
    elsif rsi.last > 70 && prices.last < sma.last
      :sell
    else
      :hold
    end
  rescue => e
    warn "MyStrategy error: #{e.message}"
    :hold
  end
end
```

## Step-by-Step Guide

### 1. Create Strategy File

Create a new file in `lib/sqa/strategy/`:

```bash
touch lib/sqa/strategy/my_strategy.rb
```

### 2. Define Strategy Class

```ruby
class SQA::Strategy::MyStrategy
  # Your implementation
end
```

### 3. Implement Trade Method

```ruby
def self.trade(vector)
  # Return :buy, :sell, or :hold
end
```

### 4. Add Error Handling

```ruby
def self.trade(vector)
  # Your logic
rescue => e
  warn "Error: #{e.message}"
  :hold  # Safe default
end
```

### 5. Write Tests

Create `test/strategy/my_strategy_test.rb`:

```ruby
require_relative '../test_helper'
require 'ostruct'

class MyStrategyTest < Minitest::Test
  def test_buy_signal
    prices = [100, 102, 104, 106, 108]
    vector = OpenStruct.new(prices: prices)
    
    signal = SQA::Strategy::MyStrategy.trade(vector)
    assert_equal :buy, signal
  end
  
  def test_hold_when_no_data
    vector = OpenStruct.new
    signal = SQA::Strategy::MyStrategy.trade(vector)
    assert_equal :hold, signal
  end
end
```

## Advanced Example

```ruby
class SQA::Strategy::AdvancedStrategy
  # Constants for configuration
  RSI_OVERSOLD = 30
  RSI_OVERBOUGHT = 70
  MIN_VOLUME_RATIO = 1.5
  
  def self.trade(vector)
    return :hold unless valid_vector?(vector)
    
    analysis = analyze_market(vector)
    generate_signal(analysis)
  end
  
  private
  
  def self.valid_vector?(vector)
    vector.respond_to?(:prices) &&
    vector.respond_to?(:volumes) &&
    vector.prices&.size >= 50
  end
  
  def self.analyze_market(vector)
    {
      rsi: SQAI.rsi(vector.prices, period: 14).last,
      trend: detect_trend(vector.prices),
      volume_spike: volume_spike?(vector.volumes)
    }
  end
  
  def self.detect_trend(prices)
    sma_short = SQAI.sma(prices, period: 20).last
    sma_long = SQAI.sma(prices, period: 50).last
    
    sma_short > sma_long ? :up : :down
  end
  
  def self.volume_spike?(volumes)
    current = volumes.last
    average = volumes.last(20).sum / 20.0
    current > (average * MIN_VOLUME_RATIO)
  end
  
  def self.generate_signal(analysis)
    if analysis[:rsi] < RSI_OVERSOLD && 
       analysis[:trend] == :up && 
       analysis[:volume_spike]
      :buy
    elsif analysis[:rsi] > RSI_OVERBOUGHT && 
          analysis[:trend] == :down && 
          analysis[:volume_spike]
      :sell
    else
      :hold
    end
  end
end
```

## Best Practices

### 1. Validate Input

```ruby
return :hold unless vector.respond_to?(:prices)
return :hold if vector.prices.nil?
return :hold if vector.prices.size < minimum_required
```

### 2. Use Available Indicators

```ruby
# All TA-Lib indicators available via SQAI
rsi = SQAI.rsi(prices, period: 14)
macd = SQAI.macd(prices)
bbands = SQAI.bbands(prices, period: 20)
```

### 3. Handle Errors Gracefully

```ruby
rescue => e
  warn "#{self.name} error: #{e.message}"
  :hold
end
```

### 4. Test Edge Cases

- Empty data
- Insufficient data
- Nil values
- Extreme values

### 5. Document Your Logic

```ruby
# Buy when:
# 1. RSI indicates oversold (< 30)
# 2. Price above 20-day SMA (uptrend)
# 3. Volume confirms (> 1.5x average)
```

## Using Your Strategy

### With Backtest

```ruby
backtest = SQA::Backtest.new(
  stock: stock,
  strategy: SQA::Strategy::MyStrategy,
  initial_cash: 10_000
)

results = backtest.run
```

### With Real-Time Stream

```ruby
stream = SQA::Stream.new(
  ticker: 'AAPL',
  strategies: [SQA::Strategy::MyStrategy]
)

stream.on_signal do |signal, data|
  puts "MyStrategy says: #{signal}"
end
```

### With Strategy Generator

```ruby
# Discover patterns and auto-generate strategies
generator = SQA::StrategyGenerator.new(stock: stock)
patterns = generator.discover_patterns
strategy_code = generator.generate_strategy(pattern_index: 0)
```

## Common Patterns

### Trend Following

```ruby
if short_ma > long_ma
  :buy
elsif short_ma < long_ma
  :sell
else
  :hold
end
```

### Mean Reversion

```ruby
deviation = (price - average) / average
if deviation < -threshold
  :buy
elsif deviation > threshold
  :sell
else
  :hold
end
```

### Momentum

```ruby
if rsi < oversold_level
  :buy
elsif rsi > overbought_level
  :sell
else
  :hold
end
```

### Breakout

```ruby
if price > recent_high && volume > threshold
  :buy
elsif price < recent_low && volume > threshold
  :sell
else
  :hold
end
```

## Next Steps

1. Study existing strategies in `lib/sqa/strategy/`
2. Read [Backtesting Guide](../advanced/backtesting.md)
3. Explore [Strategy Generator](../advanced/strategy-generator.md)
4. Learn about [Risk Management](../advanced/risk-management.md)

## Related

- [KBS Strategy](kbs.md) - Rule-based strategies
- [Consensus](consensus.md) - Combining strategies
- [Backtesting](../advanced/backtesting.md) - Testing strategies

