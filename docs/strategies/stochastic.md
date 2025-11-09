# Stochastic Oscillator Strategy

## Overview

Compares closing price to the price range over a period to identify overbought/oversold conditions and momentum changes.

## How It Works

Calculates two lines:
- **%K Line**: (Current Close - Lowest Low) / (Highest High - Lowest Low) × 100
- **%D Line**: 3-period SMA of %K

Range: 0-100

## Trading Signals

### Buy Signal
- %K crosses above %D
- Both below 20 (oversold zone)

### Sell Signal
- %K crosses below %D
- Both above 80 (overbought zone)

## Usage Example

```ruby
high = stock.df["high_price"].to_a
low = stock.df["low_price"].to_a
close = stock.df["adj_close_price"].to_a

stoch_k, stoch_d = SQAI.stoch(
  high, low, close,
  fastk_period: 14,
  slowk_period: 3,
  slowd_period: 3
)

vector = OpenStruct.new(
  stoch_k: stoch_k,
  stoch_d: stoch_d
)

signal = SQA::Strategy::Stochastic.trade(vector)
```

## Characteristics

- **Complexity**: Medium
- **Best Market**: Range-bound
- **Win Rate**: 50-60%

## Strengths

✅ Good for reversals  
✅ Works in ranging markets  
✅ Early signals  

## Weaknesses

❌ Many false signals in trends  
❌ Can stay overbought/oversold  

