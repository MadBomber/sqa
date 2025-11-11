# Running the Sinatra App Without TA-Lib

The SQA Sinatra web app can run with **limited functionality** when the TA-Lib system library is not installed. This is useful for development, testing, or deployments where installing TA-Lib is difficult.

## What Works Without TA-Lib

✅ **Basic Stock Data Display**
- Loading stock price history from cached CSV files
- Displaying price charts (candlestick and line)
- Volume charts
- Price statistics (current price, 52-week high/low)

✅ **Advanced Analysis Features**
- Market regime detection (bull/bear/sideways)
- Seasonal pattern analysis
- Risk metrics (VaR, Sharpe ratio, max drawdown)
- FPOP (Future Period Profit/Loss) analysis

✅ **Strategy Comparison**
- Comparing different trading strategies via backtesting

## What Doesn't Work Without TA-Lib

❌ **Technical Indicators**
- RSI (Relative Strength Index)
- MACD (Moving Average Convergence Divergence)
- Bollinger Bands
- Moving Averages (SMA, EMA)
- All other TA-Lib indicators (150+ total)

These endpoints will return errors:
- `GET /api/indicators/:ticker` - Returns error when indicators are called

## Running the App

### With Cached Data (No API Key Required)

1. Ensure you have cached stock data in `~/sqa_data/`:
   ```
   ~/sqa_data/
   ├── aapl.csv   # Price history
   ├── aapl.json  # Stock metadata
   ```

2. Install dependencies:
   ```bash
   cd examples/sinatra_app
   bundle install
   ```

3. Start the server:
   ```bash
   bundle exec ruby app.rb
   ```

4. Visit http://localhost:4567

### Installing TA-Lib (Optional)

To enable technical indicators, install the TA-Lib system library:

**macOS:**
```bash
brew install ta-lib
```

**Ubuntu/Debian:**
```bash
wget http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz
tar -xzf ta-lib-0.4.0-src.tar.gz
cd ta-lib/
./configure --prefix=/usr
make
sudo make install
sudo ldconfig
```

**Note:** After installing TA-Lib, you may need to reinstall the gems:
```bash
bundle install
```

## Error Handling

The app gracefully handles missing indicators by:
- Starting successfully without TA-Lib
- Showing helpful error messages when indicator endpoints are accessed
- Allowing all non-indicator features to work normally

If you see errors about indicators, it's expected behavior when TA-Lib is not available.
