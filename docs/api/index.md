# API Reference

Complete API documentation for SQA classes and modules.

## Core Classes

### SQA Module
Main module containing configuration and initialization.

- `SQA.init` - Initialize SQA system
- `SQA.config` - Access configuration
- `SQA.data_dir` - Get data directory
- `SQA.av` - Alpha Vantage API client

### Stock Class
Represents a stock with historical data.

```ruby
stock = SQA::Stock.new(ticker: 'AAPL')
```

**Methods:**
- `#ticker` - Stock symbol
- `#df` - DataFrame with price/volume data
- `#update` - Fetch latest data
- `#save_data` - Persist to disk

### DataFrame Class
High-performance wrapper around Polars DataFrame.

```ruby
df = stock.df
prices = df["adj_close_price"].to_a
```

**Methods:**
- `#height` - Number of rows
- `#column(name)` - Get column by name
- `#head(n)` - First n rows
- `#tail(n)` - Last n rows

### Strategy Classes
Base class for all trading strategies.

```ruby
signal = SQA::Strategy::RSI.trade(vector)
```

**Common Interface:**
- `.trade(vector)` - Generate trading signal
- `.trade_against(vector)` - Invert signal

## Advanced Classes

### Portfolio Class
Track positions and calculate P&L.

```ruby
portfolio = SQA::Portfolio.new(initial_cash: 10_000)
portfolio.buy('AAPL', shares: 10, price: 150.0)
```

### Backtest Class
Simulate strategies on historical data.

```ruby
backtest = SQA::Backtest.new(stock: stock, strategy: SQA::Strategy::MACD)
results = backtest.run
```

### Stream Class
Process real-time price data.

```ruby
stream = SQA::Stream.new(ticker: 'AAPL', strategies: [SQA::Strategy::RSI])
stream.on_signal { |signal, data| puts "Signal: #{signal}" }
```

## Indicator Functions (SQAI)

All indicators from TA-Lib are available via the `SQAI` module.

```ruby
# Moving averages
SQAI.sma(prices, period: 20)
SQAI.ema(prices, period: 12)

# Oscillators
SQAI.rsi(prices, period: 14)
SQAI.macd(prices, fast_period: 12, slow_period: 26, signal_period: 9)

# Volatility
SQAI.bbands(prices, period: 20, nbdev_up: 2, nbdev_down: 2)
SQAI.atr(high, low, close, period: 14)
```

See the [full indicator list](../indicators/index.md).

## Configuration

### Config Class
Manage SQA configuration.

```ruby
config = SQA::Config.new(data_dir: "~/my_data")
```

**Properties:**
- `data_dir` - Data storage location
- `log_level` - Logging verbosity
- `debug` - Debug mode flag

## Error Classes

- `SQA::ApiError` - API request failures
- `SQA::BadParameterError` - Invalid parameters
- `SQA::NoDataError` - Missing data

---

For detailed documentation, see the source code or use Ruby's introspection:

```ruby
SQA::Stock.instance_methods(false)
SQAI.methods.grep(/^[a-z]/).sort
```
