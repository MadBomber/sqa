# SMA (Simple Moving Average) Strategy

## Overview

The SMA strategy uses crossovers of short-term and long-term simple moving averages to identify trend changes and generate trading signals.

## How It Works

Compares two SMAs:
- **Short SMA**: Faster, more responsive (e.g., 50-day)
- **Long SMA**: Slower, smoother (e.g., 200-day)

## Trading Signals

### Buy Signal (Golden Cross)
Short SMA crosses **above** long SMA.

### Sell Signal (Death Cross)
Short SMA crosses **below** long SMA.

## Usage Example

```ruby
stock = SQA::Stock.new(ticker: 'AAPL')
prices = stock.df["adj_close_price"].to_a

sma_short = SQAI.sma(prices, period: 50)
sma_long = SQAI.sma(prices, period: 200)

vector = OpenStruct.new(
  sma_short: sma_short,
  sma_long: sma_long
)

signal = SQA::Strategy::SMA.trade(vector)
```

## Characteristics

- **Complexity**: Low
- **Best Market**: Trending
- **Win Rate**: 45-55%

## Strengths

✅ Simple and reliable  
✅ Filters market noise  
✅ Identifies major trends  

## Weaknesses

❌ Significant lag  
❌ Late entry/exit  
❌ Poor in ranging markets  

