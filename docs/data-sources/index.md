# Data Sources

SQA supports multiple data sources for historical stock price data.

## Available Data Sources

`SQA::Stock` defaults to **FMP** and automatically falls back to **Yahoo
Finance** if the FMP fetch fails (rate limit, missing key, network). Every
adapter exposes the same `self.recent(ticker, full:, from_date:)` interface
and returns data sorted oldest-first for TA-Lib.

### FMP — Financial Modeling Prep (Primary)
Free API key, ~250 requests/day, up to ~5 years of daily history.

**Setup:**
```bash
export FMP_API_KEY="your_key_here"
```

**Features:**
- Daily historical OHLCV
- Much higher free-tier quota than Alpha Vantage (~250/day vs 25/day)
- No split/dividend-adjusted close — `adj_close_price` mirrors `close_price`
- API key required (free)

[Get API Key →](https://site.financialmodelingprep.com/)

### Yahoo Finance (Fallback)
Used automatically when the primary source fails. Calls Yahoo's undocumented
`chart` JSON API (the same endpoints finance.yahoo.com uses).

**Features:**
- No API key required
- Unofficial API — can break if Yahoo changes their site
- If Yahoo IP-rate-limits the crumb endpoint, set `YF_COOKIE` / `YF_CRUMB`
  (from a browser session) to bypass the handshake

### Alpha Vantage
Still supported via `source: :alpha_vantage`, but no longer the default.

**Setup:**
```bash
export AV_API_KEY="your_key_here"
```

**Features:**
- Only 25 requests/day on the free tier
- Full history (`full: true`) is now premium-only; free keys fall back to
  ~100 trading days

[Get API Key →](https://www.alphavantage.co/support/#api-key)

### Stooq (not currently usable)
stooq.com now serves a JavaScript proof-of-work bot challenge on its CSV
endpoint, so `source: :stooq` cannot be reached by a plain HTTP client. The
adapter remains in the codebase in case that challenge is lifted.

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
