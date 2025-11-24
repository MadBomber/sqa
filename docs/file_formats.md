# File Formats

This document describes the CSV file formats used by SQA for data import and export.

## Portfolio CSV Formats

The `SQA::Portfolio` class supports two CSV file formats for different purposes: positions (holdings) and trade history.

### Portfolio Positions CSV

This format is used to save and load current portfolio holdings.

**Methods:**
- `portfolio.save_to_csv(filename)` - Save positions
- `SQA::Portfolio.load_from_csv(filename)` - Load positions

**Schema:**

| Column | Type | Description |
|--------|------|-------------|
| `ticker` | String | Stock ticker symbol (e.g., 'AAPL', 'MSFT') |
| `shares` | Integer | Number of shares currently held |
| `avg_cost` | Float | Average cost per share (cost basis) |
| `total_cost` | Float | Total cost basis for the entire position |

**Example File (`portfolio.csv`):**

```csv
ticker,shares,avg_cost,total_cost
AAPL,100,150.0,15000.0
MSFT,50,300.0,15000.0
GOOG,25,120.0,3000.0
```

**Usage:**

```ruby
# Save current positions to CSV
portfolio = SQA::Portfolio.new(initial_cash: 100_000)
portfolio.buy('AAPL', shares: 100, price: 150.0)
portfolio.buy('MSFT', shares: 50, price: 300.0)
portfolio.save_to_csv('my_portfolio.csv')

# Load positions from CSV
loaded_portfolio = SQA::Portfolio.load_from_csv('my_portfolio.csv')
loaded_portfolio.position('AAPL').shares  # => 100
```

**Notes:**
- The CSV includes only current positions (open holdings)
- Cash balance is NOT saved in the CSV (set via `initial_cash` parameter when loading)
- Use this format for portfolio snapshots and position tracking

---

### Trade History CSV

This format is used to export the complete log of all buy and sell transactions.

**Methods:**
- `portfolio.save_trades_to_csv(filename)` - Export trade history

**Schema:**

| Column | Type | Description |
|--------|------|-------------|
| `date` | Date | Trade execution date (YYYY-MM-DD format) |
| `ticker` | String | Stock ticker symbol |
| `action` | Symbol | Trade type: `buy` or `sell` |
| `shares` | Integer | Number of shares traded |
| `price` | Float | Price per share at execution |
| `total` | Float | Total transaction value (shares × price) |
| `commission` | Float | Commission paid for the trade |

**Example File (`trades.csv`):**

```csv
date,ticker,action,shares,price,total,commission
2024-01-15,AAPL,buy,100,150.0,15000.0,1.0
2024-01-20,MSFT,buy,50,300.0,15000.0,1.0
2024-02-05,AAPL,sell,50,160.0,8000.0,1.0
2024-02-15,GOOG,buy,25,120.0,3000.0,1.0
2024-03-01,MSFT,sell,25,310.0,7750.0,1.0
```

**Usage:**

```ruby
# Execute some trades
portfolio = SQA::Portfolio.new(initial_cash: 100_000, commission: 1.0)
portfolio.buy('AAPL', shares: 100, price: 150.0, date: Date.parse('2024-01-15'))
portfolio.buy('MSFT', shares: 50, price: 300.0, date: Date.parse('2024-01-20'))
portfolio.sell('AAPL', shares: 50, price: 160.0, date: Date.parse('2024-02-05'))

# Export complete trade history
portfolio.save_trades_to_csv('trade_history.csv')
```

**Notes:**
- This format is write-only (no corresponding `load_trades_from_csv()` method)
- Use for audit trails, tax reporting, and performance analysis
- Each row represents a single executed trade
- The `total` column does NOT include commission (commission is tracked separately)

---

## Stock Data CSV Format

Stock price and volume data is stored in CSV format with the following schema:

**Schema:**

| Column | Type | Description |
|--------|------|-------------|
| `timestamp` | String | Date in YYYY-MM-DD format |
| `open_price` | Float | Opening price |
| `high_price` | Float | Highest price during the period |
| `low_price` | Float | Lowest price during the period |
| `close_price` | Float | Closing price |
| `adj_close_price` | Float | Adjusted closing price (accounts for splits/dividends) |
| `volume` | Integer | Trading volume |

**Example File (`aapl.csv`):**

```csv
timestamp,open_price,high_price,low_price,close_price,adj_close_price,volume
2023-01-03,130.28,130.90,124.17,125.07,124.38,112117500
2023-01-04,126.89,128.66,125.08,126.36,125.66,89113600
2023-01-05,127.13,127.77,124.76,125.02,124.33,80962700
```

**Location:**
- Stock CSV files are stored in `~/sqa_data/` by default (configurable via `SQA::Config`)
- File naming convention: `{ticker}.csv` (e.g., `aapl.csv`, `msft.csv`)

**Data Ordering:**
- **CRITICAL:** Data MUST be in ascending chronological order (oldest first, newest last)
- This ordering is required for TA-Lib compatibility
- Index [0] = oldest data point, Index [last] = newest data point

**Usage:**

```ruby
# Stock data is automatically loaded/saved
stock = SQA::Stock.new(ticker: 'AAPL')
stock.df.to_csv('aapl_export.csv')  # Export to custom location

# Load from custom CSV
df = SQA::DataFrame.load(source: 'path/to/custom.csv')
```

**Notes:**
- Data is automatically fetched from Alpha Vantage or Yahoo Finance on first load
- Updates are appended and deduplicated using `concat_and_deduplicate!`
- Use `adj_close_price` for calculations that need to account for corporate actions

---

## Stock Metadata JSON Format

Stock metadata (company information) is stored in JSON format alongside CSV files.

**Location:** `~/sqa_data/{ticker}.json`

**Example File (`aapl.json`):**

```json
{
  "ticker": "aapl",
  "name": "Apple Inc.",
  "exchange": "NASDAQ",
  "source": "alpha_vantage",
  "indicators": {},
  "overview": {
    "symbol": "AAPL",
    "asset_type": "Common Stock",
    "name": "Apple Inc.",
    "exchange": "NASDAQ",
    "currency": "USD",
    "country": "USA",
    "sector": "TECHNOLOGY",
    "industry": "ELECTRONIC COMPUTERS",
    "market_capitalization": 2500000000000,
    "pe_ratio": 28.5,
    "eps": 6.05,
    "dividend_per_share": 0.92,
    "dividend_yield": 0.0055
  }
}
```

**Usage:**

```ruby
stock = SQA::Stock.new(ticker: 'AAPL')
stock.data.overview['market_capitalization']  # => 2500000000000
stock.data.overview['pe_ratio']  # => 28.5
```

---

## Configuration File Format

SQA supports YAML and TOML configuration files.

**Location:** `~/.sqa.yml` or `~/.sqa.toml`

**Example YAML (`~/.sqa.yml`):**

```yaml
data_dir: ~/sqa_data
lazy_update: false
log_level: info
plotting_library: gnuplot
```

**Example TOML (`~/.sqa.toml`):**

```toml
data_dir = "~/sqa_data"
lazy_update = false
log_level = "info"
plotting_library = "gnuplot"
```

**Available Configuration Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `data_dir` | String | `~/sqa_data` | Directory for storing stock data files |
| `lazy_update` | Boolean | `false` | If true, skip automatic data updates |
| `log_level` | Symbol | `:info` | Logging level (`:debug`, `:info`, `:warn`, `:error`) |
| `plotting_library` | Symbol | `:gnuplot` | Plotting library to use |

**Usage:**

```ruby
# Load custom configuration
config = SQA::Config.new(data_dir: '/path/to/data', lazy_update: true)
SQA.init(config)
```

---

## See Also

- [API Reference - Portfolio](api-reference/sqa_portfolio.md)
- [API Reference - Stock](api-reference/sqa_stock.md)
- [API Reference - DataFrame](api-reference/sqa_dataframe.md)
- [Data Frame Documentation](data_frame.md)
