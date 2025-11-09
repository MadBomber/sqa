# Technical Indicators

SQA provides access to 150+ technical indicators via the sqa-tai gem, which wraps the industry-standard TA-Lib library.

## Quick Reference

All indicators are available through the `SQAI` module:

```ruby
require 'sqa'

prices = [100, 102, 101, 103, 105, 104, 106]

# Simple Moving Average
sma = SQAI.sma(prices, period: 5)

# Relative Strength Index
rsi = SQAI.rsi(prices, period: 14)

# Bollinger Bands (returns 3 arrays: upper, middle, lower)
upper, middle, lower = SQAI.bbands(prices, period: 20)
```

## Indicator Categories

### Overlap Studies (Moving Averages)
- SMA - Simple Moving Average
- EMA - Exponential Moving Average
- WMA - Weighted Moving Average
- DEMA - Double Exponential Moving Average
- TEMA - Triple Exponential Moving Average
- T3 - Triple Exponential Moving Average (T3)
- MA - Moving Average (configurable type)

### Momentum Indicators
- RSI - Relative Strength Index
- STOCH - Stochastic Oscillator
- STOCHF - Stochastic Fast
- STOCHRSI - Stochastic RSI
- MACD - Moving Average Convergence Divergence
- MOM - Momentum
- ROC - Rate of Change
- CCI - Commodity Channel Index
- WILLR - Williams' %R

### Volatility Indicators
- ATR - Average True Range
- NATR - Normalized Average True Range
- TRANGE - True Range
- BBANDS - Bollinger Bands

### Volume Indicators
- AD - Chaikin A/D Line
- ADOSC - Chaikin A/D Oscillator
- OBV - On Balance Volume

### See Individual Indicators

Browse the navigation menu for detailed information about each indicator.

## Common Patterns

### Single-Value Indicators

```ruby
# Returns array of values
values = SQAI.rsi(prices, period: 14)
current_rsi = values.last
```

### Multi-Value Indicators

```ruby
# MACD returns 3 arrays
macd_line, signal_line, histogram = SQAI.macd(prices)
```

### Indicators Requiring Multiple Inputs

```ruby
# ATR needs high, low, close
high = [105, 107, 106, 108]
low = [103, 104, 103, 105]
close = [104, 106, 105, 107]

atr = SQAI.atr(high, low, close, period: 14)
```

## Full Indicator List

To see all available indicators:

```ruby
SQAI.methods.grep(/^[a-z]/).sort
```

This will list all 150+ indicators in alphabetical order.
