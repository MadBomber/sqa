# Technical Indicators Overview

## The Philosophy of Indicators

An indicator is a formula/metric on a stock's historical activity. It is presumed to be a forecast as to what the stock activity might be in the future. A single indicator is not necessarily an accurate predictor of future events, nor is any specific group of indicators.

In other words, the future is uncertain. Is it a coin flip? Heads the stock's price goes up. Tails, the stock's price goes down. It's one or the other, right? What if the price never changes? Then it's not a coin flip. Also what is the time frame involved in the forecast? Is it tomorrow, next week, next month, next year, next decade? What is the delta change in price that can be expected?

So indicators are like TV weather forecasters. Sometimes they are right. Sometimes they are wrong.

We are dealing with uncertainty. In uncertainty there is chaos. If it is possible to be right more times than you are wrong, you can make money. If you are always wrong, then always do the opposite and you will make money. When you are wrong more times than you are right... you lose.

It's a game. Game theory tells us that there are winners and losers. Bookies at the track make money every day by taking a cut of the losers' losses before giving them to the winners. Bookies always win so long as they keep their books balanced. Accounts are important.

---

## SQA Indicator System

SQA provides access to **150+ technical indicators** via the separate **sqa-tai gem**, which wraps the industry-standard TA-Lib library.

### Quick Start

All indicators are available through the `SQAI` module:

```ruby
require 'sqa'

# Get price data
stock = SQA::Stock.new(ticker: 'AAPL')
prices = stock.df["adj_close_price"].to_a

# Calculate indicators
sma = SQAI.sma(prices, period: 20)
rsi = SQAI.rsi(prices, period: 14)
macd_line, signal_line, histogram = SQAI.macd(prices)

puts "20-day SMA: #{sma.last}"
puts "14-day RSI: #{rsi.last}"
puts "MACD: #{macd_line.last}"
```

### Indicator Categories

- **Overlap Studies** - SMA, EMA, WMA, DEMA, TEMA, Bollinger Bands
- **Momentum Indicators** - RSI, MACD, Stochastic, CCI, Williams %R, Momentum
- **Volatility Indicators** - ATR, NATR, True Range, Bollinger Bands
- **Volume Indicators** - OBV, AD, Chaikin Oscillator
- **Pattern Recognition** - Candlestick patterns, chart patterns
- **And 100+ more...**

### Full Indicator List

To see all available indicators:

```ruby
SQAI.methods.grep(/^[a-z]/).sort
```

---

## Documentation

For comprehensive indicator documentation, see:

- **[Technical Indicators Guide](indicators/index.md)** - Complete guide with examples
- **[sqa-tai Gem](https://github.com/MadBomber/sqa-tai)** - Indicator library source code
- **[TA-Lib Documentation](https://ta-lib.org/)** - Underlying C library reference

---

## Using Indicators with Strategies

Indicators are commonly used within trading strategies:

```ruby
require 'sqa'

SQA.init

# Load stock data
stock = SQA::Stock.new(ticker: 'AAPL')
df = stock.df
prices = df["adj_close_price"].to_a

# Calculate indicators
rsi = SQAI.rsi(prices, period: 14)
sma_20 = SQAI.sma(prices, period: 20)
sma_50 = SQAI.sma(prices, period: 50)

# Build signal vector
require 'ostruct'
vector = OpenStruct.new(
  rsi: rsi.last,
  sma_20: sma_20.last,
  sma_50: sma_50.last,
  price: prices.last
)

# Execute strategy
signal = SQA::Strategy::RSI.trade(vector)
puts "Signal: #{signal}"  # => :buy, :sell, or :hold
```

---

## Related Documentation

- **[DataFrame API](api/dataframe.md)** - Working with price data
- **[Trading Strategies](strategies/index.md)** - Using indicators in strategies
- **[Backtesting](advanced/backtesting.md)** - Testing indicator-based strategies
- **[Strategy Generator](advanced/strategy-generator.md)** - Discovering indicator patterns

---

## External Resources

- **[TA-Lib Official Site](https://ta-lib.org/)** - Technical Analysis Library
- **[Investopedia](https://www.investopedia.com/technical-analysis-4689657)** - Technical analysis education
- **[TradingView](https://www.tradingview.com/)** - Charting platform with indicators
