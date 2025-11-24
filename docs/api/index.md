# API Reference

Complete API documentation for SQA classes and modules.

!!! tip "Auto-Generated API Documentation"
    For detailed API documentation with all methods, parameters, and return values, see the **[Complete API Reference](../api-reference/index.md)** - automatically generated from YARD comments with the same Material theme!

## Quick Navigation

| Class | Description |
|-------|-------------|
| [SQA Module](#sqa-module) | Main module, initialization, configuration |
| [SQA::Stock](#sqastock) | Stock data management |
| [SQA::DataFrame](#sqadataframe) | High-performance data structures |
| [SQA::Strategy](#sqastrategy) | Trading strategy framework |
| [SQA::Portfolio](#sqaportfolio) | Position and trade tracking |
| [SQA::Backtest](#sqabacktest) | Strategy simulation |
| [SQA::Config](#sqaconfig) | Configuration management |
| [SQAI/SQA::TAI](#sqai-indicators) | Technical indicators |

---

## SQA Module

Main module containing initialization and global accessors.

### Module Methods

#### `SQA.init(argv = ARGV)`

Initializes the SQA library. Should be called once at application startup.

```ruby
SQA.init
# Or with arguments
SQA.init("--debug")
```

**Returns:** `SQA::Config` - The configuration instance

#### `SQA.config`

Returns the current configuration object.

```ruby
SQA.config.data_dir = "~/my_data"
SQA.config.debug = true
```

**Returns:** `SQA::Config`

#### `SQA.data_dir`

Returns the data directory as a Pathname.

```ruby
path = SQA.data_dir  # => #<Pathname:/Users/you/sqa_data>
```

**Returns:** `Pathname`

#### `SQA.av_api_key`

Returns the Alpha Vantage API key from environment variables.

```ruby
key = SQA.av_api_key
```

**Returns:** `String`
**Raises:** `SQA::ConfigurationError` if not set

#### `SQA.debug?` / `SQA.verbose?`

Check if debug or verbose mode is enabled.

```ruby
puts "Debug mode" if SQA.debug?
```

**Returns:** `Boolean`

---

## SQA::Stock

Represents a stock with historical data and metadata.

### Constructor

#### `SQA::Stock.new(ticker:, source: :alpha_vantage)`

Creates a new Stock instance and loads/fetches its data.

```ruby
stock = SQA::Stock.new(ticker: 'AAPL')
stock = SQA::Stock.new(ticker: 'MSFT', source: :yahoo_finance)
```

**Parameters:**
- `ticker` (String) - Stock ticker symbol
- `source` (Symbol) - Data source (`:alpha_vantage` or `:yahoo_finance`)

**Raises:** `SQA::DataFetchError` if data cannot be fetched

### Instance Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `ticker` | String | Stock symbol (lowercase) |
| `name` | String | Company name |
| `exchange` | String | Exchange (NASDAQ, NYSE, etc.) |
| `source` | Symbol | Data source used |
| `df` | SQA::DataFrame | Price/volume DataFrame |
| `data` | SQA::DataFrame::Data | Stock metadata |
| `indicators` | Hash | Cached indicator values |
| `overview` | Hash | Company overview from API |

### Instance Methods

#### `#to_s` / `#inspect`

Returns human-readable string representation.

```ruby
stock.to_s  # => "aapl with 1258 data points from 2019-11-09 to 2024-11-08"
```

#### `#update`

Updates stock's overview data from API.

#### `#save_data`

Persists metadata to JSON file.

### Class Methods

#### `SQA::Stock.top`

Fetches top gainers, losers, and most actively traded stocks.

```ruby
top = SQA::Stock.top
top.top_gainers.each { |s| puts s.ticker }
top.top_losers.first
top.most_actively_traded
```

**Returns:** `Hashie::Mash` with three arrays

#### `SQA::Stock.connection` / `SQA::Stock.connection=`

Get or set the Faraday connection for API requests.

```ruby
# For testing with mocks
SQA::Stock.connection = mock_connection
```

---

## SQA::DataFrame

High-performance wrapper around Polars DataFrame.

### Constructor

#### `SQA::DataFrame.new(raw_data = nil, mapping: {}, transformers: {})`

Creates a new DataFrame instance.

```ruby
df = SQA::DataFrame.new(data, mapping: { "Close" => "close_price" })
```

### Instance Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `data` | Polars::DataFrame | Underlying Polars DataFrame |

### Instance Methods

#### `#columns` / `#keys`

Returns column names.

```ruby
df.columns  # => ["timestamp", "open_price", "high_price", ...]
```

#### `#[](column_name)`

Access a column (delegates to Polars).

```ruby
prices = df["adj_close_price"].to_a
```

#### `#size` / `#nrows` / `#length`

Returns number of rows.

```ruby
df.size  # => 1258
```

#### `#ncols`

Returns number of columns.

#### `#to_csv(path)`

Writes DataFrame to CSV file.

```ruby
df.to_csv("output.csv")
```

#### `#to_h`

Converts to Ruby Hash.

```ruby
hash = df.to_h
# => { timestamp: [...], close_price: [...], ... }
```

#### `#append!(other_df)` / `#concat!(other_df)`

Appends another DataFrame in place.

#### `#concat_and_deduplicate!(other_df, sort_column: "timestamp")`

Appends, removes duplicates, and sorts. Enforces ascending order for TA-Lib compatibility.

#### `#rename_columns!(mapping)`

Renames columns according to mapping.

```ruby
df.rename_columns!({ "open" => "open_price", "close" => "close_price" })
```

#### `#apply_transformers!(transformers)`

Applies transformer functions to columns.

```ruby
df.apply_transformers!({ "volume" => ->(v) { v.to_i } })
```

#### `#fpl(column:, fpop:)`

Calculates Future Period Loss/Profit.

```ruby
fpl_data = df.fpl(column: "adj_close_price", fpop: 10)
```

#### `#fpl_analysis(column:, fpop:)`

FPL analysis with risk metrics.

### Class Methods

#### `SQA::DataFrame.load(source:, mapping: {}, transformers: {})`

Loads DataFrame from CSV file.

```ruby
df = SQA::DataFrame.load(source: "path/to/data.csv")
```

#### `SQA::DataFrame.from_aofh(aofh, mapping: {}, transformers: {})`

Creates DataFrame from array of hashes.

```ruby
data = [{ "date" => "2024-01-01", "price" => 100.0 }]
df = SQA::DataFrame.from_aofh(data)
```

#### `SQA::DataFrame.from_csv_file(source, mapping: {}, transformers: {})`

Creates DataFrame from CSV file.

#### `SQA::DataFrame.from_json_file(source, mapping: {}, transformers: {})`

Creates DataFrame from JSON file.

---

## SQA::Strategy

Framework for managing trading strategies.

### Constructor

#### `SQA::Strategy.new`

Creates a new Strategy manager with empty collection.

```ruby
strategy = SQA::Strategy.new
```

### Instance Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `strategies` | Array<Method> | Collection of strategy methods |

### Instance Methods

#### `#add(strategy)`

Adds a trading strategy.

```ruby
strategy.add(SQA::Strategy::RSI)
strategy.add(MyModule.method(:custom_trade))
```

**Parameters:**
- `strategy` (Class or Method) - Strategy to add

**Raises:** `BadParameterError` if not Class or Method

#### `#execute(vector)`

Executes all strategies with given data.

```ruby
signals = strategy.execute(vector)
# => [:buy, :hold, :sell]
```

**Parameters:**
- `vector` (OpenStruct) - Data for strategy analysis

**Returns:** `Array<Symbol>` - Array of `:buy`, `:sell`, or `:hold`

#### `#auto_load(except: [:common], only: [])`

Auto-loads strategy files from strategy directory.

```ruby
strategy.auto_load(only: [:rsi, :macd])
strategy.auto_load(except: [:random])
```

#### `#available`

Lists all available strategy classes.

```ruby
strategy.available
# => [SQA::Strategy::RSI, SQA::Strategy::MACD, ...]
```

### Strategy Interface

All strategy classes must implement:

```ruby
class SQA::Strategy::MyStrategy
  def self.trade(vector)
    # Returns :buy, :sell, or :hold
  end
end
```

---

## SQA::Portfolio

Track positions and calculate P&L.

### Constructor

#### `SQA::Portfolio.new(initial_cash:, commission: 0.0)`

```ruby
portfolio = SQA::Portfolio.new(initial_cash: 10_000, commission: 1.0)
```

### Instance Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `cash` | Float | Available cash balance |
| `positions` | Hash | Ticker → share count |
| `trades` | Array | Trade history |

### Instance Methods

#### `#buy(ticker, shares:, price:)`

Purchases shares.

```ruby
portfolio.buy('AAPL', shares: 10, price: 150.0)
```

#### `#sell(ticker, shares:, price:)`

Sells shares.

```ruby
portfolio.sell('AAPL', shares: 5, price: 160.0)
```

#### `#value(current_prices)`

Calculates total portfolio value.

```ruby
total = portfolio.value({ 'AAPL' => 165.0 })
```

**Parameters:**
- `current_prices` (Hash) - Ticker → current price

---

## SQA::Backtest

Simulate strategies on historical data.

### Constructor

#### `SQA::Backtest.new(stock:, strategy:, initial_cash: 10_000, commission: 0.0)`

```ruby
backtest = SQA::Backtest.new(
  stock: stock,
  strategy: SQA::Strategy::RSI,
  initial_cash: 10_000,
  commission: 1.0
)
```

### Instance Methods

#### `#run`

Executes the backtest simulation.

```ruby
results = backtest.run
```

**Returns:** Results object with metrics:

| Metric | Description |
|--------|-------------|
| `total_return` | Total percentage return |
| `sharpe_ratio` | Risk-adjusted return |
| `sortino_ratio` | Downside risk-adjusted return |
| `max_drawdown` | Largest peak-to-trough decline |
| `win_rate` | Percentage of profitable trades |
| `num_trades` | Total number of trades |
| `final_value` | Ending portfolio value |

---

## SQA::Config

Configuration management with Hashie::Dash.

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `data_dir` | String | `~/sqa_data` | Data storage directory |
| `log_level` | Symbol | `:info` | Log level |
| `debug` | Boolean | `false` | Debug mode |
| `verbose` | Boolean | `false` | Verbose output |
| `lazy_update` | Boolean | `false` | Skip API updates |
| `plotting_library` | Symbol | `:gruff` | Plotting library |

### Instance Methods

#### `#debug?` / `#verbose?`

Check mode flags.

#### `#from_file`

Loads configuration from file (YAML, TOML, or JSON).

#### `#dump_file`

Saves configuration to file.

### Class Methods

#### `SQA::Config.reset`

Resets configuration to defaults.

#### `SQA::Config.initialized?`

Check if config has been initialized.

---

## SQAI Indicators

All indicators from TA-Lib via the `sqa-tai` gem.

### Common Usage

```ruby
prices = stock.df["adj_close_price"].to_a

# Moving Averages
sma = SQAI.sma(prices, period: 20)
ema = SQAI.ema(prices, period: 12)

# Momentum
rsi = SQAI.rsi(prices, period: 14)
macd, signal, hist = SQAI.macd(prices,
  fast_period: 12,
  slow_period: 26,
  signal_period: 9
)

# Volatility
upper, middle, lower = SQAI.bbands(prices, period: 20)
atr = SQAI.atr(high, low, close, period: 14)
```

### List All Indicators

```ruby
SQAI.methods.grep(/^[a-z]/).sort
# => [:acos, :ad, :add, :adosc, :adx, :adxr, ...]
```

See [Technical Indicators](../indicators/index.md) for complete reference.

---

## Error Classes

### SQA::DataFetchError

Raised when unable to fetch data from API or file.

```ruby
begin
  stock = SQA::Stock.new(ticker: 'INVALID')
rescue SQA::DataFetchError => e
  puts e.message
  puts e.original_error  # Wrapped exception
end
```

### SQA::ConfigurationError

Raised for invalid or missing configuration.

```ruby
begin
  key = SQA.av_api_key
rescue SQA::ConfigurationError => e
  puts "API key not set"
end
```

### SQA::BadParameterError

Raised for invalid method parameters.

```ruby
begin
  strategy.add("not a class")
rescue SQA::BadParameterError
  puts "Invalid strategy type"
end
```

### ApiError

Raised when external API returns error response.

### NotImplemented

Raised for unimplemented features.

---

## Introspection

Use Ruby introspection to explore the API:

```ruby
# List instance methods
SQA::Stock.instance_methods(false)

# List class methods
SQA::Stock.methods(false)

# Check method signature
SQA::Stock.instance_method(:initialize).parameters

# List available indicators
SQAI.methods.grep(/^[a-z]/).sort
```
