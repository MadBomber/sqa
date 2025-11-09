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

# Generate strategy from first pattern
strategy_code = generator.generate_strategy(pattern_index: 0)
puts strategy_code
```

## Configuration

```ruby
generator = SQA::StrategyGenerator.new(
  stock: stock,
  min_gain_percent: 10.0,      # Minimum profit required
  max_loss_percent: -5.0,       # Maximum acceptable loss
  fpop: 10,                     # Future periods to analyze
  min_support: 3                # Minimum pattern occurrences
)
```

## Discovering Patterns

```ruby
patterns = generator.discover_patterns

patterns.each_with_index do |pattern, i|
  puts "\nPattern #{i}:"
  puts "  Support: #{pattern[:support]} occurrences"
  puts "  Avg Gain: #{pattern[:avg_gain].round(2)}%"
  puts "  Win Rate: #{pattern[:win_rate].round(2)}%"
  
  puts "  Conditions:"
  pattern[:conditions].each do |cond|
    puts "    - #{cond[:indicator]}: #{cond[:state]}"
  end
end
```

## Generating Strategy Code

```ruby
strategy_code = generator.generate_strategy(
  pattern_index: 0,
  class_name: 'DiscoveredStrategy'
)

# Save to file
File.write('lib/sqa/strategy/discovered_strategy.rb', strategy_code)

# Load and use
require_relative 'lib/sqa/strategy/discovered_strategy'
signal = SQA::Strategy::DiscoveredStrategy.trade(vector)
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
puts "Valid regimes: #{pattern.context.valid_regimes}" # => [:bull]
puts "Sector: #{pattern.context.sector}"               # => :technology
```

## Walk-Forward Validation

```ruby
# Prevent overfitting with out-of-sample testing
validated_patterns = generator.walk_forward_validate(
  train_size: 250,  # Training period (days)
  test_size: 60     # Testing period (days)
)

validated_patterns.each do |result|
  puts "Pattern #{result[:pattern_index]}:"
  puts "  Train Return: #{result[:train_return]}%"
  puts "  Test Return: #{result[:test_return]}%"
  puts "  Robust: #{result[:robust]}"  # true if test performance acceptable
end
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

