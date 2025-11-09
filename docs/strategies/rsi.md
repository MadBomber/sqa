# RSI Strategy

## Overview

The Relative Strength Index (RSI) strategy identifies overbought and oversold conditions using momentum oscillators. It generates signals when RSI crosses key thresholds.

## How It Works

RSI is a momentum oscillator that ranges from 0 to 100:
- **Over 70**: Overbought (sell signal)
- **Under 30**: Oversold (buy signal)
- **30-70**: Neutral (hold)

## Trading Signals

### Buy Signal (`rsi.level == :oversold`)
```ruby
SQA::Strategy::RSI.trade(vector)  # => :buy when RSI < 30
```

### Sell Signal (`rsi.level == :overbought`)
```ruby
SQA::Strategy::RSI.trade(vector)  # => :sell when RSI > 70
```

## Usage Example

```ruby
require 'sqa'
require 'ostruct'

stock = SQA::Stock.new(ticker: 'AAPL')
prices = stock.df["adj_close_price"].to_a

# Calculate RSI using TA-Lib
rsi_values = SQAI.rsi(prices, period: 14)

# Create indicator data structure
rsi_data = {
  value: rsi_values.last,
  trend: rsi_values.last < 30 ? :over_sold : 
         rsi_values.last > 70 ? :over_bought : :neutral
}

vector = OpenStruct.new(rsi: rsi_data)
signal = SQA::Strategy::RSI.trade(vector)
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| Period | 14 | Number of periods for RSI calculation |
| Oversold | 30 | Lower threshold for buy signals |
| Overbought | 70 | Upper threshold for sell signals |

## Characteristics

| Attribute | Value |
|-----------|-------|
| Complexity | Low |
| Best Market | Range-bound, volatile |
| Win Rate | 50-60% |
| Time Horizon | Short to medium term |

## Strengths

- ✅ Simple and well-understood
- ✅ Works in ranging markets
- ✅ Can identify divergences
- ✅ Fast response to price changes

## Weaknesses

- ❌ Fails in strong trends
- ❌ Can stay overbought/oversold for extended periods
- ❌ Generates false signals

## Tips

1. **Combine with Trend**: Only take buy signals in uptrends
2. **Adjust Thresholds**: Use 20/80 for more conservative signals
3. **Watch Divergences**: Price makes new highs but RSI doesn't (bearish divergence)
4. **Volume Confirmation**: Stronger signals with high volume

## Related Strategies

- [Stochastic](stochastic.md) - Similar momentum oscillator
- [MACD](macd.md) - Trend-following momentum
- [Bollinger Bands](bollinger-bands.md) - Volatility-based signals

## Further Reading

- [RSI on Investopedia](https://www.investopedia.com/terms/r/rsi.asp)
- [Trading with RSI](../concepts/momentum.md)
