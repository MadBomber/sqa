# Quick Start Guide

Get up and running with SQA in just a few minutes!

## Your First Analysis (5 Minutes)

### 1. Create a Simple Script

Create a file called `my_first_analysis.rb`:

```ruby
require 'sqa'

# Initialize SQA
SQA.init

# Load Apple stock data
puts "Loading AAPL data..."
stock = SQA::Stock.new(ticker: 'AAPL')

# Display basic information
puts "\n#{stock}"
puts "Data points: #{stock.df.height}"
puts "Date range: #{stock.df['timestamp'].first} to #{stock.df['timestamp'].last}"

# Get closing prices
prices = stock.df["adj_close_price"].to_a
puts "\nCurrent price: $#{prices.last}"

# Calculate RSI (Relative Strength Index)
rsi_values = SQAI.rsi(prices, period: 14)
current_rsi = rsi_values.last.round(2)

puts "Current RSI: #{current_rsi}"
puts "Market condition: #{current_rsi < 30 ? 'Oversold' : current_rsi > 70 ? 'Overbought' : 'Neutral'}"

# Calculate Simple Moving Average
sma_20 = SQAI.sma(prices, period: 20)
sma_50 = SQAI.sma(prices, period: 50)

puts "\n20-day SMA: $#{sma_20.last.round(2)}"
puts "50-day SMA: $#{sma_50.last.round(2)}"
puts "Trend: #{sma_20.last > sma_50.last ? 'Bullish' : 'Bearish'}"
```

### 2. Run the Script

```bash
ruby my_first_analysis.rb
```

Expected output:
```
Loading AAPL data...

aapl with 1258 data points from 2019-11-09 to 2024-11-08
Data points: 1258
Date range: 2019-11-09 to 2024-11-08

Current price: $226.96
Current RSI: 48.23
Market condition: Neutral

20-day SMA: $225.45
50-day SMA: $218.32
Trend: Bullish
```

## Backtest a Strategy (10 Minutes)

Let's backtest a simple RSI trading strategy:

```ruby
require 'sqa'

SQA.init

# Load stock data
stock = SQA::Stock.new(ticker: 'AAPL')

# Create and run backtest
backtest = SQA::Backtest.new(
  stock: stock,
  strategy: SQA::Strategy::RSI,
  initial_cash: 10_000.0,
  commission: 1.0  # $1 per trade
)

puts "Running backtest for RSI strategy..."
results = backtest.run

# Display results
puts "\n=== Backtest Results ==="
puts "Total Return: #{results.total_return.round(2)}%"
puts "Sharpe Ratio: #{results.sharpe_ratio.round(2)}"
puts "Max Drawdown: #{results.max_drawdown.round(2)}%"
puts "Win Rate: #{results.win_rate.round(2)}%"
puts "\nTotal Trades: #{results.total_trades}"
puts "Winning Trades: #{results.winning_trades}"
puts "Losing Trades: #{results.losing_trades}"
puts "\nFinal Portfolio Value: $#{results.final_value.round(2)}"
```

## Use Multiple Indicators (15 Minutes)

Combine several indicators for better analysis:

```ruby
require 'sqa'

SQA.init

stock = SQA::Stock.new(ticker: 'MSFT')
prices = stock.df["adj_close_price"].to_a
volumes = stock.df["volume"].to_a

# Calculate multiple indicators
puts "Calculating indicators..."

# Trend indicators
sma_20 = SQAI.sma(prices, period: 20)
ema_12 = SQAI.ema(prices, period: 12)
ema_26 = SQAI.ema(prices, period: 26)

# Momentum indicators
rsi = SQAI.rsi(prices, period: 14)
macd_line, signal_line, histogram = SQAI.macd(
  prices,
  fast_period: 12,
  slow_period: 26,
  signal_period: 9
)

# Volatility indicators
upper, middle, lower = SQAI.bbands(prices, period: 20)

# Display current values
puts "\n=== Technical Analysis for MSFT ==="
puts "Price: $#{prices.last.round(2)}"
puts "\nTrend:"
puts "  SMA(20): $#{sma_20.last.round(2)}"
puts "  EMA(12): $#{ema_12.last.round(2)}"
puts "  EMA(26): $#{ema_26.last.round(2)}"

puts "\nMomentum:"
puts "  RSI: #{rsi.last.round(2)}"
puts "  MACD: #{macd_line.last.round(2)}"
puts "  Signal: #{signal_line.last.round(2)}"

puts "\nVolatility (Bollinger Bands):"
puts "  Upper: $#{upper.last.round(2)}"
puts "  Middle: $#{middle.last.round(2)}"
puts "  Lower: $#{lower.last.round(2)}"

# Generate trading signal
signal = case
  when rsi.last < 30 && prices.last < lower.last
    "STRONG BUY"
  when rsi.last < 40 && macd_line.last > signal_line.last
    "BUY"
  when rsi.last > 70 && prices.last > upper.last
    "STRONG SELL"
  when rsi.last > 60 && macd_line.last < signal_line.last
    "SELL"
  else
    "HOLD"
  end

puts "\nRecommended Action: #{signal}"
```

## Explore Interactively

Use the `sqa-console` for interactive exploration:

```bash
sqa-console
```

Try these commands in the console:

```ruby
# Load a stock
stock = SQA::Stock.new(ticker: 'GOOGL')

# Explore the dataframe
stock.df.head(10)

# Get column names
stock.df.columns

# Calculate any indicator
prices = stock.df["adj_close_price"].to_a
SQAI.sma(prices, period: 50)

# List all available indicators
SQAI.methods.grep(/^[a-z]/).sort

# Try different strategies
SQA::Strategy.descendants  # List all strategy classes
```

## Next Steps

Now that you've run your first analyses:

1. **[Core Concepts](../concepts/index.md)** - Understand SQA's architecture
2. **[Trading Strategies](../strategies/index.md)** - Explore built-in strategies
3. **[Advanced Features](../advanced/index.md)** - Portfolio management, streaming, etc.
4. **[API Reference](../api/index.md)** - Complete API documentation

## Common Patterns

### Load Historical Data

```ruby
stock = SQA::Stock.new(ticker: 'TSLA')
prices = stock.df["adj_close_price"].to_a
```

### Calculate Indicator

```ruby
values = SQAI.indicator_name(prices, period: 14)
```

### Apply Strategy

```ruby
require 'ostruct'
vector = OpenStruct.new(prices: prices, rsi: rsi_values)
signal = SQA::Strategy::RSI.trade(vector)
```

### Run Backtest

```ruby
backtest = SQA::Backtest.new(stock: stock, strategy: SQA::Strategy::MACD)
results = backtest.run
```

---

**Tip**: Keep the [Technical Indicators Reference](../indicators/index.md) handy as you explore!
