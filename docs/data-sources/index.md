# Data Sources

SQA supports multiple data sources for historical stock price data.

## Available Data Sources

### Alpha Vantage (Primary)
Free API with generous limits for historical and real-time data.

**Setup:**
```bash
export AV_API_KEY="your_key_here"
```

**Features:**
- Daily historical data
- Adjusted closing prices
- Up to 20 years of history
- API key required (free)

[Get API Key →](https://www.alphavantage.co/support/#api-key)

### Yahoo Finance (Fallback)
Web scraping fallback for when Alpha Vantage is unavailable.

**Features:**
- No API key required
- Less reliable (web scraping)
- Good for testing

### CSV Files (Custom)
Import your own data from CSV files.

**Format:**
```csv
Date,Open,High,Low,Close,Adj Close,Volume
2024-01-01,150.0,152.0,149.0,151.0,151.0,1000000
```

Place CSV files in `~/sqa_data/` named as `{ticker}.csv`.

## Data Format

SQA uses a standardized column format:

- `timestamp` - Date of trading day
- `open_price` - Opening price
- `high_price` - Highest price
- `low_price` - Lowest price
- `close_price` - Closing price
- `adj_close_price` - Adjusted closing price
- `volume` - Trading volume

## Configuration

Set data directory in config:

```ruby
SQA.config.data_dir = "/path/to/data"
```

Or via environment:

```bash
export SQA_DATA_DIR="/path/to/data"
```
