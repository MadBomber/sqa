# DataFrame Documentation

## Overview

The `SQA::DataFrame` class is a high-performance wrapper around the Polars DataFrame library, specifically designed for time series financial data manipulation. Polars is a Rust-backed library that provides blazingly fast operations on columnar data.

## Architecture

The DataFrame system consists of two main components:

### 1. SQA::DataFrame

The main DataFrame class that wraps Polars::DataFrame with SQA-specific convenience methods.

**Location**: `lib/sqa/data_frame.rb`

**Key Features**:
- Wraps Polars::DataFrame for high-performance operations
- Column-based vectorized operations (avoid row iterations)
- CSV and JSON import/export
- Automatic column renaming and transformations
- FPL (Future Period Loss/Profit) analysis convenience methods
- Method delegation to underlying Polars DataFrame

### 2. SQA::DataFrame::Data

A metadata storage class for stock information, separate from the price/volume data.

**Location**: `lib/sqa/data_frame/data.rb`

**Attributes**:
- `ticker` - Stock symbol (e.g., 'AAPL', 'MSFT')
- `name` - Company name
- `exchange` - Exchange symbol (NASDAQ, NYSE, etc.)
- `source` - Data source (`:alpha_vantage`, `:yahoo_finance`)
- `indicators` - Technical indicators configuration hash
- `overview` - Company overview data from Alpha Vantage

**Key Features**:
- Dual initialization: from hash (JSON) or keyword arguments
- JSON serialization with `to_json`
- Used by `SQA::Stock` to persist metadata in `~/sqa_data/ticker.json`
- All attributes are read/write accessible

## Creating DataFrames

### From Data Sources

```ruby
# Using Alpha Vantage
stock = SQA::Stock.new(ticker: 'AAPL')
df = stock.df  # SQA::DataFrame instance

# Using Yahoo Finance
stock = SQA::Stock.new(ticker: 'MSFT', source: :yahoo_finance)
df = stock.df
```

### From CSV File

```ruby
# Load CSV file (Polars-compatible)
df = SQA::DataFrame.from_csv_file('path/to/stock_data.csv')

# The underlying Polars DataFrame is accessible via .data
polars_df = df.data
```

### From JSON File

```ruby
# Load JSON array of hashes
df = SQA::DataFrame.from_json_file('path/to/stock_data.json')
```

### From Array of Hashes

```ruby
data = [
  { date: '2024-01-01', close: 150.0, volume: 1_000_000 },
  { date: '2024-01-02', close: 152.0, volume: 1_200_000 }
]

df = SQA::DataFrame.from_aofh(data)
```

## Working with DataFrames

### Column Access

```ruby
# Get column names
df.columns
# => ["timestamp", "open", "high", "low", "close", "adj_close_price", "volume"]

# Access a column (returns Polars::Series)
close_prices = df["close"]

# Convert to Ruby array
prices_array = df["adj_close_price"].to_a
```

### Basic Operations

```ruby
# Get dimensions
df.size      # Number of rows (also: df.nrows, df.length)
df.ncols     # Number of columns

# Get first/last rows
df.head(10)  # First 10 rows
df.tail(10)  # Last 10 rows

# Column statistics (via Polars)
df.data["close"].mean
df.data["volume"].sum
df.data["close"].min
df.data["close"].max
```

### Data Transformation

```ruby
# Rename columns
mapping = { 'Close' => :close, 'Volume' => :volume }
df.rename_columns!(mapping)

# Apply transformers
transformers = {
  date: ->(val) { Date.parse(val) },
  volume: ->(val) { val.to_i }
}
df.apply_transformers!(transformers)
```

### Appending DataFrames

```ruby
# Combine two DataFrames
df1.append!(df2)  # Modifies df1 in place
df1.concat!(df2)  # Alias for append!
```

### Export

```ruby
# To CSV
df.to_csv('output.csv')
df.write_csv('output.csv')  # Alias

# To Hash
hash = df.to_h
# => { close: [150.0, 152.0, ...], volume: [1_000_000, 1_200_000, ...] }
```

## FPL Analysis Methods

The DataFrame includes convenience methods for Future Period Loss/Profit analysis:

### Basic FPL Calculation

```ruby
# Calculate min/max future deltas for each point
fpl_data = df.fpl(column: "adj_close_price", fpop: 10)
# => [[min_delta, max_delta], [min_delta, max_delta], ...]
```

### Comprehensive FPL Analysis

```ruby
# Get detailed analysis with risk metrics
analysis = df.fpl_analysis(column: "adj_close_price", fpop: 10)
# => [
#   {
#     min_delta: -2.5,
#     max_delta: 5.3,
#     magnitude: 3.9,
#     risk: 7.8,
#     direction: :UP
#   },
#   ...
# ]
```

See [FPL Analysis Documentation](advanced/fpop.md) for more details.

## Working with Stock Metadata

### Creating Metadata

```ruby
# From keyword arguments
data = SQA::DataFrame::Data.new(
  ticker: 'AAPL',
  source: :alpha_vantage,
  indicators: { rsi: 14, sma: [20, 50] }
)

# From hash (JSON deserialization)
json_data = JSON.parse(File.read('aapl.json'))
data = SQA::DataFrame::Data.new(json_data)
```

### Accessing and Modifying Metadata

```ruby
# Read attributes
data.ticker        # => 'AAPL'
data.source        # => :alpha_vantage
data.indicators    # => { rsi: 14, sma: [20, 50] }

# Write attributes
data.name = 'Apple Inc.'
data.exchange = 'NASDAQ'
data.overview = {
  'company' => 'Apple Inc.',
  'sector' => 'Technology',
  'market_cap' => 2_800_000_000_000
}
```

### Persistence

```ruby
# Serialize to JSON
json_string = data.to_json

# Save to file (typically done by SQA::Stock)
File.write('aapl.json', data.to_json)

# Load from file
json_data = JSON.parse(File.read('aapl.json'))
data = SQA::DataFrame::Data.new(json_data)
```

## Performance Tips

1. **Use Column Operations**: Always prefer Polars column operations over Ruby loops
   ```ruby
   # GOOD: Vectorized operation
   df.data["close"].mean

   # BAD: Ruby loop
   df["close"].to_a.sum / df.size.to_f
   ```

2. **Access Underlying Polars**: Use `df.data` for direct Polars operations
   ```ruby
   # Direct Polars access
   filtered = df.data.filter(df.data["volume"] > 1_000_000)
   ```

3. **Avoid Unnecessary Array Conversions**: Only convert to arrays when needed
   ```ruby
   # Only convert when passing to external functions
   prices = df["adj_close_price"].to_a
   rsi = SQAI.rsi(prices, period: 14)
   ```

4. **Batch Operations**: Combine operations when possible
   ```ruby
   # Instead of multiple separate operations
   df.apply_transformers!(transformers)
   df.rename_columns!(mapping)
   ```

## Data Sources

### Alpha Vantage

**Location**: `lib/sqa/data_frame/alpha_vantage.rb`

```ruby
SQA::DataFrame::AlphaVantage.recent('AAPL', full: true)
```

**Requirements**:
- Environment variable: `AV_API_KEY` or `ALPHAVANTAGE_API_KEY`
- Rate limiting: 5 calls/minute (free tier)

### Yahoo Finance

**Location**: `lib/sqa/data_frame/yahoo_finance.rb`

```ruby
SQA::DataFrame::YahooFinance.recent('AAPL', full: true)
```

**Features**:
- No API key required
- Web scraping based (less reliable)
- Good for testing and fallback

## Adding New Data Sources

To add a new data source adapter:

1. Create `lib/sqa/data_frame/my_source.rb`
2. Define class `SQA::DataFrame::MySource`
3. Implement `self.recent(ticker, **options)` method
4. Return data in Polars-compatible format
5. Add column mapping if needed

**Example**:

```ruby
class SQA::DataFrame::MySource
  TRANSFORMERS = {
    timestamp: ->(val) { Date.parse(val) },
    volume: ->(val) { val.to_i }
  }

  def self.recent(ticker, **options)
    # Fetch data from your source
    raw_data = fetch_from_api(ticker)

    # Convert to Polars-compatible format
    SQA::DataFrame.new(raw_data, transformers: TRANSFORMERS)
  end
end
```

## Common Gotchas

1. **DataFrame vs Polars**:
   - `df` is `SQA::DataFrame`
   - `df.data` is `Polars::DataFrame`

2. **Column Names**:
   - Column names are strings, not symbols
   - Use `df["close"]` not `df[:close]`

3. **Method Delegation**:
   - Unknown methods are delegated to Polars::DataFrame
   - Check Polars docs for advanced operations

4. **Indicators Need Arrays**:
   - Extract data with `.to_a` before passing to SQAI/TAI functions
   - Example: `prices = df["close"].to_a`

## Related Documentation

- [FPL Analysis](advanced/fpop.md) - Future Period Loss/Profit utilities
- [Indicators](indicators/index.md) - Technical indicator integration
- [Polars Documentation](https://pola-rs.github.io/polars-book/) - Underlying library

## Example: Complete Workflow

```ruby
require 'sqa'

SQA.init

# Load stock data
stock = SQA::Stock.new(ticker: 'AAPL')

# Access DataFrame
df = stock.df

# Get price array for indicators
prices = df["adj_close_price"].to_a

# Calculate technical indicators
sma_20 = SQAI.sma(prices, period: 20)
rsi_14 = SQAI.rsi(prices, period: 14)

# FPL analysis
fpl_analysis = df.fpl_analysis(fpop: 10)
high_quality = SQA::FPOP.filter_by_quality(
  fpl_analysis,
  min_magnitude: 5.0,
  max_risk: 25.0
)

# Access stock metadata
puts "Ticker: #{stock.ticker}"
puts "Exchange: #{stock.exchange}"
puts "Source: #{stock.source}"

# Export data
df.to_csv("aapl_prices.csv")
File.write("aapl_metadata.json", stock.data.to_json)
```
