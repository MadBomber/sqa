# EMA (Exponential Moving Average) Strategy

## Overview

Similar to SMA but gives more weight to recent prices, making it more responsive to price changes.

## How It Works

Uses EMA crossovers for signals:
- **Short EMA**: 12 or 20-period
- **Long EMA**: 26 or 50-period

## Trading Signals

### Buy Signal
Short EMA crosses above long EMA.

### Sell Signal
Short EMA crosses below long EMA.

## Usage Example

```ruby
prices = stock.df["adj_close_price"].to_a

ema_short = SQAI.ema(prices, period: 12)
ema_long = SQAI.ema(prices, period: 26)

vector = OpenStruct.new(
  ema_short: ema_short,
  ema_long: ema_long
)

signal = SQA::Strategy::EMA.trade(vector)
```

## Characteristics

- **Complexity**: Low
- **Best Market**: Trending
- **Win Rate**: 45-55%

## Strengths

✅ Faster than SMA  
✅ Better for short-term trading  
✅ Reduces lag  

## Weaknesses

❌ More false signals  
❌ Still lags in fast markets  

