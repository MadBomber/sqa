# DataFrame API Reference

## Overview

`SQA::DataFrame` is a high-performance wrapper around the Polars DataFrame library, specifically optimized for time series financial data manipulation. Polars is a Rust-backed library that provides blazingly fast columnar data operations.

The DataFrame system consists of two main components:

1. **SQA::DataFrame** - The main wrapper class with financial data convenience methods
2. **SQA::DataFrame::Data** - Metadata storage for stock information (separate from price data)

## Architecture

### Why Polars?

Polars provides:
- **Blazing Speed**: Rust-backed implementation with zero-copy operations
- **Memory Efficiency**: Columnar storage format optimized for analytics
- **Lazy Evaluation**: Query optimization before execution
- **Type Safety**: Strong typing with automatic type inference

### Wrapper Benefits

`SQA::DataFrame` wraps Polars to provide:
- Financial data-specific convenience methods
- Consistent column naming across data sources
- FPL (Future Period Loss/Profit) analysis methods
- Seamless integration with SQA workflows
- Method delegation for full Polars API access

## Class: SQA::DataFrame

**Location**: `lib/sqa/data_frame.rb`

### Instance Attributes

```ruby
df.data  # => Polars::DataFrame - The underlying Polars DataFrame
```

Direct access to the Polars DataFrame for advanced operations.

### Class Methods

#### `.new(raw_data = nil, mapping: {}, transformers: {})`

Creates a new DataFrame instance with optional column mapping and transformations.

**Parameters:**
- `raw_data` (Hash, Array, Polars::DataFrame, nil) - Initial data
- `mapping` (Hash) - Column name mappings `{ "source_name" => :target_name }`
- `transformers` (Hash) - Value transformation lambdas `{ column: ->(v) { transform(v) } }`

**Returns:** `SQA::DataFrame` instance

**Important:** Columns are renamed FIRST, then transformers are applied. Transformers receive renamed column names.

**Example:**
```ruby
# From array of hashes
data = [
  { 'Date' => '2024-01-01', 'Close' => '150.5' },
  { 'Date' => '2024-01-02', 'Close' => '152.3' }
]

mapping = { 'Date' => :timestamp, 'Close' => :close_price }
transformers = { close_price: ->(v) { v.to_f } }

df = SQA::DataFrame.new(data, mapping: mapping, transformers: transformers)
```

#### `.load(source:, transformers: {}, mapping: {})`

Loads a DataFrame from a CSV file with optional transformations.

**Parameters:**
- `source` (String, Pathname) - Path to CSV file
- `mapping` (Hash) - Column name mappings (usually empty for cached data)
- `transformers` (Hash) - Value transformations (usually empty for cached data)

**Returns:** `SQA::DataFrame` instance

**Note:** For cached CSV files, transformers and mapping should typically be empty since transformations were already applied when the data was first fetched.

**Example:**
```ruby
# Load from cached CSV (no transformations needed)
df = SQA::DataFrame.load(source: "~/sqa_data/aapl.csv")

# Load with migration transformations
df = SQA::DataFrame.load(
  source: "old_data.csv",
  mapping: { 'date' => :timestamp },
  transformers: { volume: ->(v) { v.to_i } }
)
```

#### `.from_csv_file(source, mapping: {}, transformers: {})`

Alias for `.load()` - loads DataFrame from CSV file.

**Example:**
```ruby
df = SQA::DataFrame.from_csv_file('stock_data.csv')
```

#### `.from_json_file(source, mapping: {}, transformers: {})`

Loads DataFrame from JSON file containing array of hashes.

**Parameters:**
- `source` (String, Pathname) - Path to JSON file
- `mapping` (Hash) - Column name mappings
- `transformers` (Hash) - Value transformations

**Returns:** `SQA::DataFrame` instance

**Example:**
```ruby
# JSON format: [{"date": "2024-01-01", "price": 150.5}, ...]
df = SQA::DataFrame.from_json_file('prices.json')
```

#### `.from_aofh(aofh, mapping: {}, transformers: {})`

Creates DataFrame from Array of Hashes (AOFH).

**Parameters:**
- `aofh` (Array<Hash>) - Array of hash records
- `mapping` (Hash) - Column name mappings
- `transformers` (Hash) - Value transformations

**Returns:** `SQA::DataFrame` instance

**Example:**
```ruby
data = [
  { date: '2024-01-01', price: 150.5, volume: 1000000 },
  { date: '2024-01-02', price: 152.0, volume: 1100000 }
]

df = SQA::DataFrame.from_aofh(data)
```

### Instance Methods

#### Column Operations

##### `#columns`

Returns array of column names.

**Returns:** `Array<String>`

**Example:**
```ruby
df.columns
# => ["timestamp", "open_price", "high_price", "low_price",
#     "close_price", "adj_close_price", "volume"]
```

##### `#keys`

Alias for `#columns`.

##### `#vectors`

Alias for `#columns`.

##### `#[](column_name)`

Access column data (returns Polars::Series).

**Parameters:**
- `column_name` (String) - Name of column

**Returns:** `Polars::Series`

**Example:**
```ruby
# Get close prices
close_series = df["close_price"]

# Convert to array
prices = df["close_price"].to_a
# => [150.5, 152.0, 151.5, ...]
```

##### `#rename_columns!(mapping)`

Renames columns in place according to mapping.

**Parameters:**
- `mapping` (Hash) - Hash of old_name => new_name mappings

**Returns:** `nil` (modifies in place)

**Important:**
- Normalizes symbol keys to strings
- Tries exact match first, then lowercase match
- Polars requires both keys and values to be strings

**Example:**
```ruby
mapping = { 'Open' => :open_price, 'Close' => :close_price }
df.rename_columns!(mapping)
```

##### `#apply_transformers!(transformers)`

Applies transformation functions to columns in place.

**Parameters:**
- `transformers` (Hash) - Hash of column_name => lambda mappings

**Returns:** `nil` (modifies in place)

**Example:**
```ruby
transformers = {
  volume: ->(v) { v.to_i },
  close_price: ->(v) { v.to_f.round(2) }
}
df.apply_transformers!(transformers)
```

#### Dimension Methods

##### `#size`

Returns number of rows.

**Returns:** `Integer`

**Aliases:** `#nrows`, `#length`

**Example:**
```ruby
df.size      # => 250
df.nrows     # => 250
df.length    # => 250
```

##### `#ncols`

Returns number of columns.

**Returns:** `Integer`

**Example:**
```ruby
df.ncols  # => 7
```

#### Data Combination

##### `#append!(other_df)`

Appends another DataFrame's rows to this one.

**Parameters:**
- `other_df` (SQA::DataFrame) - DataFrame to append

**Returns:** `nil` (modifies in place)

**Raises:** `RuntimeError` if row count doesn't match expected

**Aliases:** `#concat!`

**Example:**
```ruby
# Combine two DataFrames
df1.append!(df2)

# Verify
puts df1.size  # => original size + df2 size
```

#### Export Methods

##### `#to_csv(path_to_file)`

Writes DataFrame to CSV file.

**Parameters:**
- `path_to_file` (String, Pathname) - Destination file path

**Returns:** `nil`

**Example:**
```ruby
df.to_csv("~/sqa_data/aapl_backup.csv")
```

##### `#to_h`

Converts DataFrame to Hash with symbolized keys.

**Returns:** `Hash` - Column name symbols to arrays

**Example:**
```ruby
df.to_h
# => {
#   timestamp: ["2024-01-01", "2024-01-02", ...],
#   close_price: [150.5, 152.0, ...],
#   volume: [1000000, 1100000, ...]
# }
```

#### FPL Analysis Methods

##### `#fpl(column: "adj_close_price", fpop: 14)`

Calculates Future Period Loss/Profit for each data point.

**Parameters:**
- `column` (String, Symbol) - Price column name
- `fpop` (Integer) - Future Period of Performance (days to look ahead)

**Returns:** `Array<Array<Float, Float>>` - Array of [min_delta, max_delta] pairs

**Example:**
```ruby
# Look 10 days into the future
fpl_data = df.fpl(column: "adj_close_price", fpop: 10)
# => [[-2.5, 5.3], [-1.2, 3.8], ...]
```

##### `#fpl_analysis(column: "adj_close_price", fpop: 14)`

Comprehensive FPL analysis with risk metrics and direction classification.

**Parameters:**
- `column` (String, Symbol) - Price column name
- `fpop` (Integer) - Future Period of Performance

**Returns:** `Array<Hash>` - Array of analysis hashes

**Hash Keys:**
- `:min_delta` - Minimum future price change %
- `:max_delta` - Maximum future price change %
- `:magnitude` - Average expected movement %
- `:risk` - Volatility range
- `:direction` - `:UP`, `:DOWN`, `:UNCERTAIN`, or `:FLAT`

**Example:**
```ruby
analysis = df.fpl_analysis(column: "adj_close_price", fpop: 10)

analysis.first
# => {
#   min_delta: -2.5,
#   max_delta: 5.3,
#   magnitude: 3.9,
#   risk: 7.8,
#   direction: :UP
# }

# Filter high-quality opportunities
filtered = SQA::FPOP.filter_by_quality(
  analysis,
  min_magnitude: 5.0,
  max_risk: 25.0,
  directions: [:UP]
)
```

#### Delegation to Polars

Any method not defined on `SQA::DataFrame` is automatically delegated to the underlying `Polars::DataFrame`.

**Example:**
```ruby
# These call Polars methods directly
df.head(10)          # First 10 rows
df.tail(5)           # Last 5 rows
df.describe          # Statistical summary
df.filter(...)       # Polars filter expression
df.select(...)       # Select columns
df.with_column(...)  # Add computed column
```

See [Polars documentation](https://pola-rs.github.io/polars-book/) for full API.

### Class Helper Methods

These utility methods are primarily used internally by data source adapters.

#### `.generate_mapping(keys)`

Generates column name mapping from source keys to underscored symbols.

**Parameters:**
- `keys` (Array) - Array of column names

**Returns:** `Hash` - Mapping hash

**Example:**
```ruby
keys = ['Open', 'High', 'Low', 'Close']
mapping = SQA::DataFrame.generate_mapping(keys)
# => { "Open" => :open, "High" => :high, "Low" => :low, "Close" => :close }
```

#### `.underscore_key(key)`

Converts a key to underscored, lowercase symbol.

**Parameters:**
- `key` (String, Symbol) - Key to convert

**Returns:** `Symbol`

**Example:**
```ruby
SQA::DataFrame.underscore_key('AdjClose')    # => :adj_close
SQA::DataFrame.underscore_key('OpenPrice')   # => :open_price
```

**Alias:** `.sanitize_key`

#### `.normalize_keys(hash, adapter_mapping: {})`

Normalizes hash keys to underscored symbols.

**Parameters:**
- `hash` (Hash) - Hash to normalize
- `adapter_mapping` (Hash) - Optional custom mappings

**Returns:** `Hash` - Hash with normalized keys

#### `.rename(hash, mapping)`

Renames hash keys according to mapping.

**Parameters:**
- `hash` (Hash) - Hash to modify
- `mapping` (Hash) - Key mappings

**Returns:** `Hash` - Modified hash

#### `.is_date?(value)`

Checks if value looks like a date string (YYYY-MM-DD format).

**Parameters:**
- `value` (String) - Value to check

**Returns:** `Boolean`

**Example:**
```ruby
SQA::DataFrame.is_date?("2024-01-01")  # => true
SQA::DataFrame.is_date?("150.5")       # => false
```

---

## Class: SQA::DataFrame::Data

**Location**: `lib/sqa/data_frame/data.rb`

A metadata storage class for stock information, completely separate from the price/volume DataFrame.

### Attributes

All attributes are read/write accessible via `attr_accessor`:

- `ticker` (String) - Stock symbol (e.g., 'AAPL', 'MSFT')
- `name` (String) - Company name
- `exchange` (String) - Exchange symbol (NASDAQ, NYSE, etc.)
- `source` (Symbol) - Data source (`:alpha_vantage`, `:yahoo_finance`)
- `indicators` (Hash) - Technical indicators configuration
- `overview` (Hash) - Company overview data from Alpha Vantage

### Instance Methods

#### `.new(data_hash = nil, ticker: nil, name: nil, exchange: nil, source: :alpha_vantage, indicators: {}, overview: {})`

Dual initialization constructor supporting both hash and keyword arguments.

**From Hash (JSON deserialization):**
```ruby
json_data = JSON.parse(File.read('aapl.json'))
data = SQA::DataFrame::Data.new(json_data)
```

**From Keyword Arguments:**
```ruby
data = SQA::DataFrame::Data.new(
  ticker: 'AAPL',
  source: :alpha_vantage,
  indicators: { rsi: 14, sma: [20, 50] }
)
```

#### `#to_json(*args)`

Serializes metadata to JSON string.

**Returns:** `String` - JSON representation

**Example:**
```ruby
json_string = data.to_json
File.write('aapl.json', json_string)
```

#### `#to_h`

Converts metadata to Hash.

**Returns:** `Hash` - Hash representation

**Example:**
```ruby
hash = data.to_h
# => {
#   ticker: 'AAPL',
#   name: 'Apple Inc.',
#   exchange: 'NASDAQ',
#   source: :alpha_vantage,
#   indicators: { rsi: 14 },
#   overview: { ... }
# }
```

### Usage in SQA::Stock

`SQA::Stock` uses `DataFrame::Data` to persist metadata separately from price data:

**Persistence Pattern:**
```ruby
# In SQA::Stock
@data_path = SQA.data_dir + "#{@ticker}.json"  # Metadata file
@df_path = SQA.data_dir + "#{@ticker}.csv"     # Price data file

# Save metadata
@data_path.write(@data.to_json)

# Load metadata
@data = SQA::DataFrame::Data.new(JSON.parse(@data_path.read))
```

---

## Data Source Adapters

### Alpha Vantage Adapter

**Location**: `lib/sqa/data_frame/alpha_vantage.rb`

**Class:** `SQA::DataFrame::AlphaVantage`

#### Constants

```ruby
# Standard column headers
HEADERS = [
  :timestamp,       # 0
  :open_price,      # 1
  :high_price,      # 2
  :low_price,       # 3
  :close_price,     # 4
  :adj_close_price, # 5
  :volume           # 6
]

# Maps Alpha Vantage CSV columns to standard headers
HEADER_MAPPING = {
  "timestamp" => HEADERS[0],  # :timestamp
  "open"      => HEADERS[1],  # :open_price
  "high"      => HEADERS[2],  # :high_price
  "low"       => HEADERS[3],  # :low_price
  "close"     => HEADERS[4],  # :close_price
  "volume"    => HEADERS[6]   # :volume
}

# Value transformations applied after renaming
TRANSFORMERS = {
  HEADERS[1] => ->(v) { v.to_f.round(3) },  # :open_price
  HEADERS[2] => ->(v) { v.to_f.round(3) },  # :high_price
  HEADERS[3] => ->(v) { v.to_f.round(3) },  # :low_price
  HEADERS[4] => ->(v) { v.to_f.round(3) },  # :close_price
  HEADERS[6] => ->(v) { v.to_i }            # :volume
}
```

#### `.recent(ticker, full: false, from_date: nil)`

Fetches recent price data from Alpha Vantage API.

**Parameters:**
- `ticker` (String) - Stock symbol
- `full` (Boolean) - If true, fetches full history; otherwise last 100 days
- `from_date` (Date, String, nil) - Optional date filter

**Returns:** `SQA::DataFrame` - Wrapped DataFrame with standardized columns

**Requirements:**
- Environment variable: `AV_API_KEY` or `ALPHAVANTAGE_API_KEY`
- Free tier: 5 calls/minute, 500 calls/day

**Important:** Alpha Vantage doesn't provide separate adjusted close, so `close_price` is duplicated as `adj_close_price` for compatibility.

**Example:**
```ruby
# Fetch recent 100 days
df = SQA::DataFrame::AlphaVantage.recent('AAPL')

# Fetch full history
df = SQA::DataFrame::AlphaVantage.recent('AAPL', full: true)

# Fetch from specific date
df = SQA::DataFrame::AlphaVantage.recent('AAPL', from_date: '2024-01-01')
```

### Yahoo Finance Adapter

**Location**: `lib/sqa/data_frame/yahoo_finance.rb`

**Class:** `SQA::DataFrame::YahooFinance`

#### Constants

```ruby
HEADERS = [
  :timestamp,       # 0
  :open_price,      # 1
  :high_price,      # 2
  :low_price,       # 3
  :close_price,     # 4
  :adj_close_price, # 5
  :volume           # 6
]

HEADER_MAPPING = {
  "Date"      => HEADERS[0],
  "Open"      => HEADERS[1],
  "High"      => HEADERS[2],
  "Low"       => HEADERS[3],
  "Close"     => HEADERS[4],
  "Adj Close" => HEADERS[5],
  "Volume"    => HEADERS[6]
}
```

#### `.recent(ticker)`

Scrapes recent price data from Yahoo Finance website.

**Parameters:**
- `ticker` (String) - Stock symbol

**Returns:** `SQA::DataFrame` - Wrapped DataFrame with standardized columns

**Note:** Web scraping based, less reliable than API but requires no API key.

**Example:**
```ruby
df = SQA::DataFrame::YahooFinance.recent('AAPL')
```

### Creating Custom Adapters

To add a new data source:

1. Create `lib/sqa/data_frame/my_source.rb`
2. Define constants: `HEADERS`, `HEADER_MAPPING`, `TRANSFORMERS`
3. Implement `.recent(ticker, **options)` class method
4. **MUST** return `SQA::DataFrame`, not raw Polars::DataFrame

**Example Template:**
```ruby
class SQA::DataFrame::MySource
  HEADERS = [
    :timestamp,
    :open_price,
    :high_price,
    :low_price,
    :close_price,
    :adj_close_price,
    :volume
  ]

  HEADER_MAPPING = {
    "date" => HEADERS[0],
    "open" => HEADERS[1],
    # ... map source columns to standard headers
  }

  TRANSFORMERS = {
    HEADERS[1] => ->(v) { v.to_f.round(3) },
    HEADERS[6] => ->(v) { v.to_i }
  }

  def self.recent(ticker, **options)
    # 1. Fetch data from API/source
    raw_data = fetch_from_source(ticker)

    # 2. Convert to Polars DataFrame
    polars_df = Polars.read_csv(StringIO.new(raw_data))

    # 3. MUST wrap in SQA::DataFrame with mapping and transformers
    sqa_df = SQA::DataFrame.new(
      polars_df,
      mapping: HEADER_MAPPING,
      transformers: TRANSFORMERS
    )

    # 4. Add any missing columns if needed
    # Example: Alpha Vantage doesn't have adj_close_price
    # sqa_df.data = sqa_df.data.with_column(
    #   sqa_df.data["close_price"].alias("adj_close_price")
    # )

    # 5. Return wrapped DataFrame
    sqa_df
  end
end
```

---

## Usage Examples

### Basic Workflow

```ruby
require 'sqa'

SQA.init

# Load stock (fetches from Alpha Vantage by default)
stock = SQA::Stock.new(ticker: 'AAPL')

# Access DataFrame
df = stock.df

# Get dimensions
puts "Rows: #{df.size}, Columns: #{df.ncols}"
# => Rows: 250, Columns: 7

# Get column names
puts df.columns.join(", ")
# => timestamp, open_price, high_price, low_price, close_price, adj_close_price, volume

# Extract price array for indicators
prices = df["adj_close_price"].to_a

# Calculate technical indicators (via sqa-tai gem)
sma_20 = SQAI.sma(prices, period: 20)
rsi_14 = SQAI.rsi(prices, period: 14)

puts "Current Price: #{prices.last}"
puts "20-day SMA: #{sma_20.last}"
puts "14-day RSI: #{rsi_14.last}"
```

### Working with Polars Directly

```ruby
# Access underlying Polars DataFrame
polars_df = df.data

# Filter using Polars expressions
high_volume = polars_df.filter(
  Polars.col("volume") > 10_000_000
)

# Calculate statistics
avg_close = polars_df["close_price"].mean
max_high = polars_df["high_price"].max
total_volume = polars_df["volume"].sum

# Add computed columns
polars_df = polars_df.with_column(
  (Polars.col("close_price") - Polars.col("open_price"))
    .alias("daily_change")
)
```

### FPL Analysis Workflow

```ruby
# Get FPL analysis
fpl_analysis = df.fpl_analysis(column: "adj_close_price", fpop: 10)

# Find high-quality opportunities
opportunities = SQA::FPOP.filter_by_quality(
  fpl_analysis,
  min_magnitude: 5.0,    # At least 5% expected move
  max_risk: 25.0,        # Max 25% risk range
  directions: [:UP]      # Only upward moves
)

puts "Found #{opportunities.size} high-quality opportunities"

opportunities.each_with_index do |opp, idx|
  puts "\nOpportunity ##{idx + 1}:"
  puts "  Expected Move: #{opp[:magnitude].round(2)}%"
  puts "  Risk: #{opp[:risk].round(2)}%"
  puts "  Direction: #{opp[:direction]}"
  puts "  Range: #{opp[:min_delta].round(2)}% to #{opp[:max_delta].round(2)}%"
end
```

### Data Export and Import

```ruby
# Export to CSV
df.to_csv("aapl_prices.csv")

# Export to Hash
hash = df.to_h
File.write("aapl_prices.json", hash.to_json)

# Load from CSV
df = SQA::DataFrame.load(source: "aapl_prices.csv")

# Load from JSON
df = SQA::DataFrame.from_json_file("aapl_prices.json")
```

### Combining DataFrames

```ruby
# Load historical data
historical_df = SQA::DataFrame.load(source: "aapl_historical.csv")

# Fetch recent updates
recent_df = SQA::DataFrame::AlphaVantage.recent('AAPL')

# Combine
historical_df.append!(recent_df)

# Save updated dataset
historical_df.to_csv("aapl_updated.csv")
```

---

## Performance Considerations

### 1. Use Column Operations

**Good:**
```ruby
# Vectorized operation (fast)
avg = df.data["close_price"].mean
```

**Bad:**
```ruby
# Ruby loop (slow)
prices = df["close_price"].to_a
avg = prices.sum / prices.size.to_f
```

### 2. Minimize Array Conversions

Only convert to arrays when necessary (e.g., passing to external functions):

```ruby
# Only convert for indicators
prices = df["adj_close_price"].to_a
rsi = SQAI.rsi(prices, period: 14)

# Use Polars for everything else
avg = df.data["adj_close_price"].mean  # No conversion needed
```

### 3. Batch Operations

Combine operations when possible:

```ruby
# Apply all transformations at once
df = SQA::DataFrame.new(
  raw_data,
  mapping: mapping,
  transformers: transformers
)

# Instead of separate calls
df.rename_columns!(mapping)
df.apply_transformers!(transformers)
```

### 4. Use Polars Native Operations

Leverage Polars' lazy evaluation and query optimization:

```ruby
# Polars can optimize this entire chain
result = df.data
  .filter(Polars.col("volume") > 1_000_000)
  .select(["timestamp", "close_price"])
  .head(100)
```

### 5. Avoid Repeated Column Access

Cache column data if used multiple times:

```ruby
# Good: cache the series
close_prices = df["close_price"]
avg = close_prices.mean
max = close_prices.max
min = close_prices.min

# Bad: repeated access
avg = df["close_price"].mean
max = df["close_price"].max
min = df["close_price"].min
```

---

## Common Gotchas

### 1. DataFrame vs Polars

```ruby
df        # => SQA::DataFrame (wrapper)
df.data   # => Polars::DataFrame (underlying data)
```

Use `df.data` for direct Polars operations.

### 2. Column Names are Strings

```ruby
# Correct
df["close_price"]

# Wrong
df[:close_price]  # Polars uses strings, not symbols
```

### 3. Transformers Expect Renamed Columns

Order matters in initialization:
1. Columns are renamed FIRST
2. Then transformers are applied

Transformers receive the NEW column names, not the original names.

```ruby
mapping = { 'Close' => :close_price }
transformers = { close_price: ->(v) { v.to_f } }  # Use renamed name

df = SQA::DataFrame.new(data, mapping: mapping, transformers: transformers)
```

### 4. Indicators Need Arrays

All SQAI/TAI indicator functions require Ruby arrays:

```ruby
# Correct
prices = df["adj_close_price"].to_a
rsi = SQAI.rsi(prices, period: 14)

# Wrong
rsi = SQAI.rsi(df["adj_close_price"], period: 14)  # Series not supported
```

### 5. Method Delegation

Unknown methods are delegated to `Polars::DataFrame`:

```ruby
# These work via delegation
df.head(10)
df.describe

# Check Polars docs for advanced features
```

### 6. CSV Round-Trip Considerations

When loading cached CSV files, don't reapply transformers:

```ruby
# First time: apply transformers
df = SQA::DataFrame::AlphaVantage.recent('AAPL')
df.to_csv("aapl.csv")

# Later: don't reapply transformers (already applied)
df = SQA::DataFrame.load(source: "aapl.csv")
# NOT: load(source: "aapl.csv", transformers: TRANSFORMERS)
```

### 7. Data Source Return Types

All data source adapters MUST return `SQA::DataFrame`, not raw `Polars::DataFrame`:

```ruby
# Correct
def self.recent(ticker)
  polars_df = fetch_data(ticker)
  SQA::DataFrame.new(polars_df, mapping: MAPPING)  # Wrap it!
end

# Wrong
def self.recent(ticker)
  fetch_data(ticker)  # Returns Polars::DataFrame
end
```

---

## Recent Fixes (2024-11)

The DataFrame architecture underwent significant fixes to resolve type safety issues:

### Issue 1: Missing DataFrame::Data Class
**Problem:** Stock metadata class didn't exist
**Fix:** Created `SQA::DataFrame::Data` with dual initialization

### Issue 2: Type Mismatches
**Problem:** Adapters returned `Polars::DataFrame` instead of `SQA::DataFrame`
**Fix:** All adapters now wrap DataFrames before returning

### Issue 3: Missing .load() Method
**Problem:** Stock tried to call non-existent `.load()` method
**Fix:** Added class method with proper signature

### Issue 4: Column Mapping Order
**Problem:** Transformers applied before column renaming
**Fix:** Renamed columns FIRST, then apply transformers

### Issue 5: Key Type Mismatches
**Problem:** Symbol keys used where Polars expects strings
**Fix:** Convert all keys to strings in `rename_columns!()`

### Issue 6: Incorrect Polars API Usage
**Problem:** Used `Polars::DataFrame.read_csv()` and `df["col"].gt_eq()`
**Fix:** Use `Polars.read_csv()` and `Polars.col("col") >=`

See `DATAFRAME_ARCHITECTURE_REVIEW.md` for detailed analysis.

---

## Related Documentation

- [Stock Class](stock.md) - Using DataFrames with Stock objects
- [FPL Analysis](../advanced/fpop.md) - Future Period Loss/Profit utilities
- [Technical Indicators](../indicators/index.md) - SQAI/TAI integration
- [Polars Documentation](https://pola-rs.github.io/polars-book/) - Underlying library
- [Data Sources](../data-sources/index.md) - Alpha Vantage and Yahoo Finance

---

## Complete Example

```ruby
require 'sqa'

# Initialize
SQA.init

# Load stock data
stock = SQA::Stock.new(ticker: 'AAPL')
df = stock.df

puts "=== Stock Information ==="
puts "Ticker: #{stock.ticker}"
puts "Exchange: #{stock.exchange}"
puts "Source: #{stock.source}"
puts "Data Points: #{df.size}"

puts "\n=== Price Data ==="
prices = df["adj_close_price"].to_a
puts "Current Price: $#{prices.last.round(2)}"
puts "52-Week High: $#{prices.max.round(2)}"
puts "52-Week Low: $#{prices.min.round(2)}"

puts "\n=== Technical Indicators ==="
sma_20 = SQAI.sma(prices, period: 20)
sma_50 = SQAI.sma(prices, period: 50)
rsi_14 = SQAI.rsi(prices, period: 14)

puts "20-day SMA: $#{sma_20.last.round(2)}"
puts "50-day SMA: $#{sma_50.last.round(2)}"
puts "14-day RSI: #{rsi_14.last.round(2)}"

puts "\n=== FPL Analysis ==="
fpl_analysis = df.fpl_analysis(column: "adj_close_price", fpop: 10)
latest = fpl_analysis.last

puts "10-Day Forecast:"
puts "  Direction: #{latest[:direction]}"
puts "  Expected Move: #{latest[:magnitude].round(2)}%"
puts "  Risk: #{latest[:risk].round(2)}%"
puts "  Range: #{latest[:min_delta].round(2)}% to #{latest[:max_delta].round(2)}%"

# Export data
df.to_csv("aapl_export.csv")
File.write("aapl_metadata.json", stock.data.to_json)

puts "\n=== Export Complete ==="
puts "Data saved to aapl_export.csv"
puts "Metadata saved to aapl_metadata.json"
```

---

**See Also:**
- [Getting Started Guide](../getting-started/quick-start.md)
- [Examples Directory](https://github.com/MadBomber/sqa/tree/main/examples)
- [Contributing Guide](../contributing/index.md)
