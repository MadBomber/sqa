# Consensus Strategy

## Overview

Aggregates signals from multiple strategies and makes trading decisions based on majority vote. Reduces risk of acting on single false signals.

## How It Works

Executes 5 independent strategies and counts votes:
- **Majority Buy**: More buy signals than sell → Buy
- **Majority Sell**: More sell signals than buy → Sell
- **Tie or No Consensus**: Hold

## Trading Signals

```ruby
strategies = [Strategy1, Strategy2, Strategy3, Strategy4, Strategy5]
votes = strategies.map { |s| s.trade(vector) }
# votes = [:buy, :buy, :sell, :hold, :buy]

# Count: buy=3, sell=1, hold=1
# Result: :buy (majority)
```

## Usage Example

```ruby
vector = OpenStruct.new(
  rsi: rsi_data,
  macd: macd_data,
  prices: prices
)

signal = SQA::Strategy::Consensus.trade(vector)
# Returns :buy, :sell, or :hold based on majority
```

## Characteristics

- **Complexity**: Medium
- **Best Market**: All markets
- **Win Rate**: 50-60%
- **Reduces**: False signals

## Strengths

✅ Reduces false positives  
✅ More reliable than single strategy  
✅ Democratic decision making  
✅ Can combine different approaches  

## Weaknesses

❌ May be slower to act  
❌ Can dilute strong signals  
❌ Requires multiple data inputs  

## Tips

1. **Diverse Strategies**: Mix trend and momentum strategies
2. **Odd Number**: Use odd number of strategies to avoid ties
3. **Weighted Voting**: Consider weighting better-performing strategies
4. **Threshold**: Require super-majority (e.g., 4 out of 5) for higher conviction

