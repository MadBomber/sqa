# Volume Breakout Strategy

## Overview

Identifies price breakouts confirmed by high trading volume for stronger signal reliability.

## How It Works

Looks for:
1. Price breaking above recent high or below recent low
2. Volume exceeding 1.5x the average volume

## Trading Signals

### Buy Signal
- Price breaks above 20-period high
- Volume > 1.5× average volume

### Sell Signal
- Price breaks below 20-period low
- Volume > 1.5× average volume

## Usage Example

```ruby
prices = stock.df["adj_close_price"].to_a
volumes = stock.df["volume"].to_a

vector = OpenStruct.new(
  prices: prices,
  volumes: volumes
)

signal = SQA::Strategy::VolumeBreakout.trade(vector)
```

## Characteristics

- **Complexity**: Medium
- **Best Market**: Breakout/trending
- **Win Rate**: 50-60%

## Strengths

✅ Volume confirmation reduces false breakouts  
✅ Catches strong moves  
✅ Clear entry points  

## Weaknesses

❌ Rare signals  
❌ Can whipsaw on false breakouts  
❌ Requires both price and volume data  

