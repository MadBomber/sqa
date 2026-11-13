# Strategy Generator

## Overview

Reverse-engineer profitable trades to discover patterns and automatically generate executable trading strategies.

## How It Works

1. **Identify Profitable Points**: Scan historical data for entry points that led to profitable exits
2. **Capture Indicator States**: Record all indicator values at those profitable points
3. **Mine Patterns**: Find common combinations of indicator states
4. **Generate Strategies**: Create executable strategy code from patterns

## Quick Start

```ruby
require 'sqa'

# Load stock data
stock = SQA::Stock.new(ticker: 'AAPL')

# Create generator
generator = SQA::StrategyGenerator.new(
  stock: stock,
  min_gain_percent: 10.0,  # Minimum 10% profit
  fpop: 10                  # Look ahead 10 periods
)

# Discover patterns
patterns = generator.discover_patterns

# Generate a strategy (a callable returning :buy or :hold) from the first pattern
strategy = generator.generate_strategy(pattern_index: 0)
signal = strategy.call(vector)
```

## Configuration

```ruby
generator = SQA::StrategyGenerator.new(
  stock: stock,
  min_gain_percent: 10.0,      # Minimum profit required
  min_loss_percent: -5.0,      # Loss threshold (defaults to -min_gain_percent)
  fpop: 10,                    # Future periods to analyze
  inflection_window: 3         # Window for detecting local min/max
)

# Minimum pattern occurrences is set when discovering patterns
patterns = generator.discover_patterns(min_pattern_frequency: 3)
```

## Discovering Patterns

```ruby
patterns = generator.discover_patterns

patterns.each_with_index do |pattern, i|
  puts "\nPattern #{i}:"
  puts "  Frequency: #{pattern.frequency} occurrences"
  puts "  Avg Gain: #{pattern.avg_gain.round(2)}%"
  puts "  Success Rate: #{pattern.success_rate.round(2)}%"

  puts "  Conditions:"
  pattern.conditions.each do |indicator, state|
    puts "    - #{indicator}: #{state}"
  end
end
```

## Generating Strategies

```ruby
# strategy_type: :proc (default), :class, or :kbs
strategy_class = generator.generate_strategy(
  pattern_index: 0,
  strategy_type: :class
)

# The generated class responds to .trade like the built-in strategies
signal = strategy_class.trade(vector)

# Or generate the top N patterns at once
strategies = generator.generate_strategies(top_n: 5, strategy_type: :class)
```

## Context-Aware Patterns

```ruby
# Include market context in pattern discovery
patterns = generator.discover_context_aware_patterns(
  analyze_regime: true,     # Include bull/bear/sideways
  analyze_seasonal: true,   # Include month/quarter
  sector: :technology       # Sector classification
)

# Patterns include context
pattern = patterns.first
puts "Valid in: #{pattern.context.valid_months}"      # => [10, 11, 12]
puts "Market regime: #{pattern.context.market_regime}" # => :bull
puts "Sector: #{pattern.context.sector}"               # => :technology
```

## Walk-Forward Validation

```ruby
# Prevent overfitting with out-of-sample testing
result = generator.walk_forward_validate(
  train_size: 250,  # Training period (days)
  test_size: 60,    # Testing period (days)
  step_size: 30     # Days to step forward each iteration
)

puts "Iterations: #{result[:total_iterations]}"
puts "Validated patterns: #{result[:validated_patterns].size}"
result[:validation_results]  # per-iteration out-of-sample results
```

## Example Output

```ruby
# Generated strategy example
class SQA::Strategy::Pattern_1
  def self.trade(vector)
    return :hold unless valid_data?(vector)
    
    # Pattern: Oversold RSI + Bullish MACD + High Volume
    if vector.rsi[:trend] == :over_sold &&
       vector.macd[:crossover] == :bullish &&
       vector.volume_ratio > 1.5
      :buy
    else
      :hold
    end
  end
  
  private
  
  def self.valid_data?(vector)
    vector.respond_to?(:rsi) &&
    vector.respond_to?(:macd) &&
    vector.respond_to?(:volume_ratio)
  end
end
```

## Best Practices

1. **Use Sufficient Data**: At least 1-2 years of historical data
2. **Validate Patterns**: Use walk-forward testing
3. **Filter by Support**: Require minimum pattern occurrences (3-5)
4. **Consider Context**: Include market regime and seasonality
5. **Backtest Generated Strategies**: Always test before using live

## Related

- [Genetic Programming](../genetic_programming.md) - Optimize strategy parameters
- [KBS Strategy](../strategies/kbs.md) - Rule-based strategies
- [Backtesting](backtesting.md) - Test discovered strategies

