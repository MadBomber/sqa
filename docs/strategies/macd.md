# MACD Strategy

## Overview

Moving Average Convergence Divergence (MACD) is a trend-following momentum indicator that shows the relationship between two moving averages.

## How It Works

MACD consists of three components:
- **MACD Line**: 12-period EMA - 26-period EMA
- **Signal Line**: 9-period EMA of MACD Line
- **Histogram**: MACD Line - Signal Line

## Trading Signals

### Buy Signal (Bullish Crossover)
MACD line crosses **above** the signal line.

```ruby
SQA::Strategy::MACD.trade(vector)  # => :buy
```

### Sell Signal (Bearish Crossover)
MACD line crosses **below** the signal line.

```ruby
SQA::Strategy::MACD.trade(vector)  # => :sell
```

## Usage Example

```ruby
stock = SQA::Stock.new(ticker: 'AAPL')
prices = stock.df["adj_close_price"].to_a

# Calculate MACD
macd_line, signal_line, histogram = SQAI.macd(
  prices,
  fast_period: 12,
  slow_period: 26,
  signal_period: 9
)

vector = OpenStruct.new(
  macd: [macd_line, signal_line, histogram]
)

signal = SQA::Strategy::MACD.trade(vector)
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| Fast Period | 12 | Fast EMA period |
| Slow Period | 26 | Slow EMA period |
| Signal Period | 9 | Signal line EMA period |

## Characteristics

| Attribute | Value |
|-----------|-------|
| Complexity | Medium |
| Best Market | Trending |
| Win Rate | 45-55% |
| Time Horizon | Medium to long term |

## Strengths

- ✅ Excellent trend following
- ✅ Combines trend and momentum
- ✅ Clear crossover signals
- ✅ Can detect trend changes early

## Weaknesses

- ❌ Lags in fast markets
- ❌ Whipsaws in ranging markets
- ❌ False signals during consolidation

## Tips

1. **Confirm with Trend**: Best in established trends
2. **Histogram Divergence**: Watch for divergence with price
3. **Zero Line Cross**: Additional confirmation signal
4. **Multiple Timeframes**: Align daily and weekly signals

## Related Strategies

- [EMA](ema.md) - Uses moving average crossovers
- [SMA](sma.md) - Similar crossover approach
- [RSI](rsi.md) - Complementary momentum indicator

## Further Reading

- [MACD on Investopedia](https://www.investopedia.com/terms/m/macd.asp)
