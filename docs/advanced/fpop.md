# FPOP - Future Period of Performance

## Overview

Calculate future returns, risk metrics, and direction classification to evaluate trading opportunities.

## Quick Start

```ruby
require 'sqa'

stock = SQA::Stock.new(ticker: 'AAPL')
prices = stock.df["adj_close_price"].to_a

# Calculate FPL (Future Period Loss/Profit)
fpl_data = SQA::FPOP.fpl(prices, fpop: 10)
# => [[min_delta, max_delta], ...]

# Comprehensive analysis
analysis = SQA::FPOP.fpl_analysis(prices, fpop: 10)
puts "Risk: #{analysis[:risk]}%"
puts "Direction: #{analysis[:direction]}"  # :UP, :DOWN, :FLAT
```

## Methods

### Basic FPL Calculation

```ruby
prices = [100, 102, 105, 103, 107, 110]
fpl = SQA::FPOP.fpl(prices, fpop: 3)

# For each point, calculates min/max change over next 3 periods
# fpl[0] = [min(102,105,103) - 100, max(102,105,103) - 100]
#        = [100-100, 105-100] = [0, 5]
```

### Comprehensive Analysis

```ruby
analysis = SQA::FPOP.fpl_analysis(prices, fpop: 10)

# Returns hash with:
# {
#   fpl: [[min_delta, max_delta], ...],
#   risk: 15.5,              # Max downside %
#   reward: 25.2,            # Max upside %
#   direction: :UP,          # Overall trend
#   magnitude: 10.3,         # Average move size
#   quality_score: 0.75      # Risk/reward ratio
# }
```

### Quality Filtering

```ruby
filtered = SQA::FPOP.filter_by_quality(
  analysis,
  min_magnitude: 5.0,      # Minimum 5% move
  max_risk: 25.0,          # Maximum 25% downside
  directions: [:UP]         # Only upward moves
)

# Returns only high-quality opportunities
```

## Integration with Strategy Generator

```ruby
generator = SQA::StrategyGenerator.new(
  stock: stock,
  min_gain_percent: 10.0,
  fpop: 10,                  # Use 10-period lookahead
  max_fpl_risk: 20.0         # Filter by max acceptable risk
)

patterns = generator.discover_patterns
# Only includes patterns with acceptable risk/reward
```

## DataFrame Methods

```ruby
# Convenient DataFrame extensions
df = stock.df

# Add FPL columns
df_with_fpl = df.fpl(fpop: 10)

# Add full analysis
df_with_analysis = df.fpl_analysis(fpop: 10)

# Now has columns: fpl_min, fpl_max, fpl_risk, fpl_direction, etc.
```

## Use Cases

### 1. Opportunity Screening

```ruby
stocks = ['AAPL', 'GOOGL', 'MSFT']

stocks.each do |ticker|
  stock = SQA::Stock.new(ticker: ticker)
  prices = stock.df["adj_close_price"].to_a
  
  analysis = SQA::FPOP.fpl_analysis(prices, fpop: 10)
  
  if analysis[:reward] > 15.0 && analysis[:risk] < 10.0
    puts "#{ticker}: Good risk/reward (#{analysis[:reward]}/#{analysis[:risk]})"
  end
end
```

### 2. Entry Point Validation

```ruby
# Check if current point offers good risk/reward
current_analysis = SQA::FPOP.fpl_analysis(prices, fpop: 10)

if current_analysis[:direction] == :UP && 
   current_analysis[:quality_score] > 0.7
  puts "Strong buy opportunity"
end
```

### 3. Stop Loss Calculation

```ruby
analysis = SQA::FPOP.fpl_analysis(prices, fpop: 10)

# Set stop loss based on expected risk
entry_price = prices.last
stop_loss = entry_price * (1 - analysis[:risk] / 100)

puts "Entry: $#{entry_price}"
puts "Stop Loss: $#{stop_loss}"
puts "Target: $#{entry_price * (1 + analysis[:reward] / 100)}"
```

## Parameters

- `fpop`: Future periods to analyze (default: 10)
- `min_magnitude`: Minimum move size to consider (%)
- `max_risk`: Maximum acceptable downside (%)
- `directions`: Filter by `:UP`, `:DOWN`, or `:FLAT`

## Related

- [Strategy Generator](strategy-generator.md) - Uses FPOP for pattern quality
- [Risk Management](risk-management.md) - Position sizing based on risk
- [Backtesting](backtesting.md) - Validate FPOP predictions

