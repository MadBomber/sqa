# SQA Web App - Quick Start Guide

Get the SQA web application running in 5 minutes.

## 1. Prerequisites

```bash
# Install TA-Lib (macOS)
brew install ta-lib

# Start Redis
redis-server

# Set API key (optional, uses Yahoo Finance as fallback)
export AV_API_KEY="your_key_here"
```

## 2. Install Dependencies

```bash
cd examples/sinatra_app
bundle install
```

## 3. Start the Application

```bash
ruby app.rb
```

The app will start on http://localhost:4567

## 4. Quick Tour

### Home Page
- Click on any quick link ticker (AAPL, MSFT, etc.)
- Or enter a custom ticker in the search box

### Dashboard
- View interactive price charts (candlestick or line)
- See volume chart
- Check RSI and MACD indicators
- View key metrics (52-week high/low, current RSI, market regime)
- Compare all strategies at once

### Analysis Page
- Market regime detection (bull/bear/sideways)
- Seasonal patterns (best months and quarters)
- FPOP (Future Period) analysis
- Risk metrics (VaR, Sharpe ratio, max drawdown)

### Backtest Page
- Select a strategy (RSI, MACD, SMA, EMA, Bollinger Bands, KBS)
- View detailed backtest results
- Compare all strategies side-by-side

## 5. Keyboard Shortcuts

- `Ctrl/Cmd + K` - Open ticker search
- `Escape` - Close modal

## 6. API Examples

### Get Stock Data
```bash
curl http://localhost:4567/api/stock/AAPL
```

### Get Technical Indicators
```bash
curl http://localhost:4567/api/indicators/AAPL
```

### Run Backtest
```bash
curl -X POST http://localhost:4567/api/backtest/AAPL \
  -d "strategy=RSI"
```

### Get Market Analysis
```bash
curl http://localhost:4567/api/analyze/AAPL
```

### Compare Strategies
```bash
curl -X POST http://localhost:4567/api/compare/AAPL
```

## 7. Development Mode

Auto-reload on file changes:

```bash
gem install rerun
rerun 'ruby app.rb'
```

## 8. Troubleshooting

**Port already in use:**
```bash
# Kill process on port 4567
lsof -ti:4567 | xargs kill -9
```

**TA-Lib not found:**
```bash
# Reinstall TA-Lib
brew reinstall ta-lib
```

**Redis connection error:**
```bash
# Start Redis
redis-server &
```

**Stock data not loading:**
- Check internet connection
- Verify ticker symbol is valid
- Try a different ticker (e.g., AAPL, MSFT, GOOGL)

## 9. Popular Tickers

Try these popular stocks:

**Tech:**
- AAPL (Apple)
- MSFT (Microsoft)
- GOOGL (Google)
- AMZN (Amazon)
- NVDA (NVIDIA)
- TSLA (Tesla)

**Finance:**
- JPM (JP Morgan)
- BAC (Bank of America)
- GS (Goldman Sachs)

**ETFs:**
- SPY (S&P 500)
- QQQ (NASDAQ 100)
- DIA (Dow Jones)

## 10. Next Steps

- Explore different strategies on the Backtest page
- Compare seasonal patterns across multiple stocks
- Check market regime before making trade decisions
- Use FPOP analysis to identify high-probability setups

## Support

See README.md for full documentation and API reference.

---

Happy analyzing! 📊
