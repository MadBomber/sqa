# FPOP - Future Period of Performance

## Overview

Calculate future returns, risk metrics, and direction classification to evaluate trading opportunities.

FPOP looks *ahead* from each bar, so it describes what happened after a bar,
not what will happen after today. Both `fpl` and `fpl_analysis` return one
entry per bar that has at least one later price; the final bar has none, so
the result is one element shorter than the price array.

## Quick Start

```ruby
require 'sqa'

stock = SQA::Stock.new(ticker: 'AAPL')
prices = stock.df["adj_close_price"].to_a

# Calculate FPL (Future Period Loss/Profit)
fpl_data = SQA::FPOP.fpl(prices, fpop: 10)
# => [[min_delta, max_delta], ...]   one pair per bar

# Per-bar analysis (an Array of Hashes)
analysis = SQA::FPOP.fpl_analysis(prices, fpop: 10)
latest = analysis.last   # the most recent bar with a future window
puts "Risk: #{latest[:risk]}%"
puts "Direction: #{latest[:direction]}"  # :UP, :DOWN, :UNCERTAIN, :FLAT
```

## Methods

### Basic FPL Calculation

```ruby
prices = [100, 102, 105, 103, 107, 110]
fpl = SQA::FPOP.fpl(prices, fpop: 3)

# For each point, the min/max percentage change over the next 3 periods.
# fpl[0] looks at [102, 105, 103]:
#   min = (102 - 100) / 100 * 100 = 2.0
#   max = (105 - 100) / 100 * 100 = 5.0
fpl[0]  # => [2.0, 5.0]
```

### Comprehensive Analysis

```ruby
analysis = SQA::FPOP.fpl_analysis(prices, fpop: 3)

analysis.class  # => Array (one Hash per bar)
analysis.first
# => {
#   min_delta: 2.0,                         # Worst % change in the window
#   max_delta: 5.0,                         # Best % change in the window
#   risk: 3.0,                              # Range: max_delta - min_delta
#   direction: :UP,                         # :UP, :DOWN, :UNCERTAIN, or :FLAT
#   magnitude: 3.5,                         # Average of min_delta and max_delta
#   interpretation: "UP: 3.5% (±1.5% risk)"
# }
```

Direction values:

- `:UP` - the price rose during the window and did not fall
- `:DOWN` - the price fell during the window and did not rise
- `:UNCERTAIN` - the price both rose and fell within the window
- `:FLAT` - no clear direction (see `SQA::FPOP.determine_direction` for the
  zero-delta edge cases)

### Quality Filtering

`filter_by_quality` returns the **indices** of the bars that pass every
criterion:

```ruby
indices = SQA::FPOP.filter_by_quality(
  analysis,
  min_magnitude: 5.0,      # Minimum 5% average move
  max_risk: 25.0,          # Maximum 25% range between best and worst
  directions: [:UP]        # Only upward moves
)

indices.map { |i| analysis[i] }  # the matching bars
```

### Risk/Reward Ratios

```ruby
ratios = SQA::FPOP.risk_reward_ratios(analysis)
# => one Float per bar: |magnitude| / risk (0.0 when risk is 0)
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

The DataFrame wrappers read a price column (default `"adj_close_price"`) and
return the same values as the module methods. They do not add columns.

```ruby
df = stock.df

fpl_data = df.fpl(fpop: 10)             # => Array of [min_delta, max_delta]
analysis = df.fpl_analysis(fpop: 10)    # => Array of Hashes

analysis.last[:direction]
```

## Use Cases

### 1. Opportunity Screening

```ruby
stocks = ['AAPL', 'GOOGL', 'MSFT']

stocks.each do |ticker|
  stock = SQA::Stock.new(ticker: ticker)
  prices = stock.df["adj_close_price"].to_a

  latest = SQA::FPOP.fpl_analysis(prices, fpop: 10).last

  if latest[:max_delta] > 15.0 && latest[:risk] < 10.0
    puts "#{ticker}: Good risk/reward (#{latest[:max_delta]}/#{latest[:risk]})"
  end
end
```

### 2. Entry Point Validation

```ruby
# Check whether a historical entry point offered good risk/reward
analysis = SQA::FPOP.fpl_analysis(prices, fpop: 10)
ratios = SQA::FPOP.risk_reward_ratios(analysis)

entry_index = analysis.size - 1
if analysis[entry_index][:direction] == :UP && ratios[entry_index] > 0.7
  puts "Strong buy opportunity"
end
```

### 3. Stop Loss Calculation

```ruby
analysis = SQA::FPOP.fpl_analysis(prices, fpop: 10)
latest = analysis.last

# Set stop loss based on the worst move seen in the window
entry_price = prices.last
stop_loss = entry_price * (1 + latest[:min_delta] / 100)

puts "Entry: $#{entry_price}"
puts "Stop Loss: $#{stop_loss}"
puts "Target: $#{entry_price * (1 + latest[:max_delta] / 100)}"
```

## Parameters

- `fpop`: Future periods to analyze (default: 14)
- `min_magnitude`: Minimum average move to consider (%)
- `max_risk`: Maximum acceptable range between best and worst move (%)
- `directions`: Filter by `:UP`, `:DOWN`, `:UNCERTAIN`, or `:FLAT`

## Related

- [Strategy Generator](strategy-generator.md) - Uses FPOP for pattern quality
- [Risk Management](risk-management.md) - Position sizing based on risk
- [Backtesting](backtesting.md) - Validate FPOP predictions
