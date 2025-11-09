# Mean Reversion Strategy

## Overview

Based on the theory that prices tend to return to their average over time. Buys when price is below average and sells when above.

## How It Works

Calculates distance from moving average:
- **Below average**: Expect price to rise (buy)
- **Above average**: Expect price to fall (sell)

## Trading Signals

### Buy Signal
Price significantly below SMA (undervalued).

### Sell Signal
Price significantly above SMA (overvalued).

## Usage Example

```ruby
prices = stock.df["adj_close_price"].to_a
sma = SQAI.sma(prices, period: 20)

current_price = prices.last
current_sma = sma.last
deviation = ((current_price - current_sma) / current_sma) * 100

# Buy if more than 5% below SMA
signal = if deviation < -5.0
  :buy
elsif deviation > 5.0
  :sell
else
  :hold
end
```

## Characteristics

- **Complexity**: Low
- **Best Market**: Range-bound, low volatility
- **Win Rate**: 55-65%

## Strengths

✅ High win rate in ranging markets  
✅ Clear mathematical basis  
✅ Works well with statistical analysis  

## Weaknesses

❌ Fails in trending markets  
❌ Can lead to "catching falling knives"  
❌ Requires stable market conditions  

