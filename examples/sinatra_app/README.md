# SQA Web Application

A modern web interface for the SQA (Simple Qualitative Analysis) stock analysis library. Built with Sinatra, featuring interactive charts powered by Plotly.js, and a responsive UI for comprehensive stock market analysis.

## Features

### 📊 Interactive Dashboard
- **Candlestick & Line Charts** - Visualize price movements with professional financial charts
- **Volume Analysis** - Track trading volume with color-coded bars
- **Technical Indicators** - RSI, MACD, SMA, EMA, Bollinger Bands
- **Key Metrics** - 52-week high/low, current RSI, market regime
- **Real-time Data** - Fetch latest stock data from Alpha Vantage or Yahoo Finance

### 🤖 Strategy Backtesting
- **6 Built-in Strategies** - RSI, MACD, SMA, EMA, Bollinger Bands, KBS
- **Detailed Metrics** - Total return, Sharpe ratio, max drawdown, win rate
- **Strategy Comparison** - Compare all strategies side-by-side
- **Performance Analytics** - Profit factor, average win/loss, total trades

### 📈 Market Analysis
- **Market Regime Detection** - Identify bull/bear/sideways markets
- **Seasonal Patterns** - Discover best months and quarters for trading
- **FPOP Analysis** - Future Period Loss/Profit projections
- **Risk Metrics** - VaR, Sharpe ratio, maximum drawdown

### 🎨 Modern UI/UX
- **Responsive Design** - Works on desktop, tablet, and mobile
- **Dark Navigation** - Professional gradient navbar
- **Interactive Cards** - Hover effects and smooth transitions
- **Keyboard Shortcuts** - Ctrl/Cmd+K for quick search
- **Loading States** - Spinners and progress indicators

## Installation

### Prerequisites

- Ruby >= 3.2
- Bundler
- TA-Lib library (for technical indicators)
- Redis (for KBS strategy)

### Install TA-Lib

**macOS:**
```bash
brew install ta-lib
```

**Ubuntu/Debian:**
```bash
sudo apt-get install ta-lib-dev
```

**Windows:**
Download from [TA-Lib website](http://ta-lib.org/)

### Install Dependencies

```bash
cd examples/sinatra_app
bundle install
```

### Set Up API Keys

SQA supports two data sources:

**Option 1: Alpha Vantage (Recommended)**
```bash
export AV_API_KEY="your_api_key_here"
```
Get a free API key from [Alpha Vantage](https://www.alphavantage.co/support/#api-key)

**Option 2: Yahoo Finance**
No API key required, but less reliable and may have rate limits.

### Start Redis (for KBS)

```bash
redis-server
```

## Usage

### Start the Application

```bash
ruby app.rb
```

Or using Rack:
```bash
rackup
```

The application will start on `http://localhost:4567`

### Navigate the App

1. **Home Page** - Quick access to popular stocks
2. **Search** - Enter any ticker symbol (e.g., AAPL, MSFT, GOOGL)
3. **Dashboard** - View charts and indicators
4. **Analysis** - Market regime, seasonal patterns, FPOP
5. **Backtest** - Test trading strategies

### Keyboard Shortcuts

- `Ctrl/Cmd + K` - Open ticker search modal
- `Escape` - Close modal

## API Endpoints

### Stock Data

```http
GET /api/stock/:ticker
```

Returns stock price data with OHLCV (Open, High, Low, Close, Volume).

**Response:**
```json
{
  "ticker": "AAPL",
  "current_price": 175.50,
  "change": 2.30,
  "change_percent": 1.33,
  "high_52w": 198.23,
  "low_52w": 124.17,
  "dates": ["2023-01-01", "2023-01-02", ...],
  "open": [170.0, 171.5, ...],
  "high": [172.0, 173.0, ...],
  "low": [169.5, 170.8, ...],
  "close": [171.0, 172.3, ...],
  "volume": [50000000, 48000000, ...]
}
```

### Technical Indicators

```http
GET /api/indicators/:ticker
```

Returns calculated technical indicators.

**Response:**
```json
{
  "dates": ["2023-01-01", ...],
  "rsi": [45.2, 48.1, ...],
  "macd": [0.5, 0.7, ...],
  "macd_signal": [0.4, 0.6, ...],
  "macd_hist": [0.1, 0.1, ...],
  "bb_upper": [180.0, ...],
  "bb_middle": [175.0, ...],
  "bb_lower": [170.0, ...],
  "sma_20": [173.5, ...],
  "sma_50": [170.2, ...],
  "ema_20": [174.0, ...]
}
```

### Backtest Strategy

```http
POST /api/backtest/:ticker
Content-Type: application/x-www-form-urlencoded

strategy=RSI
```

**Response:**
```json
{
  "total_return": 15.45,
  "annualized_return": 12.30,
  "sharpe_ratio": 1.25,
  "max_drawdown": 8.50,
  "win_rate": 58.33,
  "total_trades": 24,
  "profit_factor": 1.85,
  "avg_win": 3.20,
  "avg_loss": -2.10
}
```

### Market Analysis

```http
GET /api/analyze/:ticker
```

**Response:**
```json
{
  "regime": {
    "type": "bull",
    "volatility": "medium",
    "strength": 0.75,
    "trend": 15.2
  },
  "seasonal": {
    "best_months": [10, 11, 12],
    "worst_months": [6, 7, 8],
    "best_quarters": [4, 1],
    "has_pattern": true
  },
  "fpop": [...],
  "risk": {
    "var_95": -0.025,
    "sharpe_ratio": 1.15,
    "max_drawdown": 0.12
  }
}
```

### Compare Strategies

```http
POST /api/compare/:ticker
```

**Response:**
```json
[
  {
    "strategy": "RSI",
    "return": 15.45,
    "sharpe": 1.25,
    "drawdown": 8.50,
    "win_rate": 58.33,
    "trades": 24
  },
  ...
]
```

## Technology Stack

### Backend
- **Sinatra** - Lightweight Ruby web framework
- **SQA Library** - Stock analysis and backtesting
- **TA-Lib** - Technical analysis indicators (via sqa-tai gem)
- **Polars** - High-performance DataFrame operations
- **Redis** - KBS blackboard persistence

### Frontend
- **Plotly.js** - Interactive financial charts
- **Font Awesome** - Icons
- **Vanilla JavaScript** - No framework dependencies
- **CSS3** - Modern styling with gradients and animations

## File Structure

```
sinatra_app/
├── app.rb                 # Main Sinatra application
├── config.ru              # Rack configuration
├── Gemfile                # Ruby dependencies
├── public/
│   ├── css/
│   │   └── style.css      # Application styles
│   └── js/
│       └── app.js         # Client-side JavaScript
├── views/
│   ├── layout.erb         # Base template
│   ├── index.erb          # Home page
│   ├── dashboard.erb      # Main dashboard with charts
│   ├── analyze.erb        # Analysis page
│   ├── backtest.erb       # Backtesting interface
│   ├── portfolio.erb      # Portfolio optimizer (coming soon)
│   └── error.erb          # Error page
└── README.md              # This file
```

## Routes

| Route | Method | Description |
|-------|--------|-------------|
| `/` | GET | Home page with quick links |
| `/dashboard/:ticker` | GET | Main dashboard for ticker |
| `/analyze/:ticker` | GET | Market analysis page |
| `/backtest/:ticker` | GET | Strategy backtesting page |
| `/portfolio` | GET | Portfolio optimization (coming soon) |
| `/api/stock/:ticker` | GET | Get stock data |
| `/api/indicators/:ticker` | GET | Get technical indicators |
| `/api/backtest/:ticker` | POST | Run strategy backtest |
| `/api/analyze/:ticker` | GET | Get market analysis |
| `/api/compare/:ticker` | POST | Compare all strategies |

## Configuration

### Port and Binding

Edit `app.rb`:

```ruby
set :port, 4567
set :bind, '0.0.0.0'  # Allow external connections
```

### Data Source

The SQA library automatically selects the data source:
1. Alpha Vantage (if `AV_API_KEY` is set)
2. Yahoo Finance (fallback)

## Deployment

### Using Rack

```bash
rackup -p 4567
```

### Using Passenger (Production)

```bash
passenger start
```

### Using Docker

```dockerfile
FROM ruby:3.3
WORKDIR /app
COPY Gemfile* ./
RUN bundle install
COPY . .
EXPOSE 4567
CMD ["ruby", "app.rb"]
```

## Development

### Adding New Routes

Edit `app.rb`:

```ruby
get '/my-route/:ticker' do
  ticker = params[:ticker].upcase
  # ... logic
  erb :my_template
end
```

### Adding New Views

Create `views/my_template.erb`:

```erb
<div class="dashboard">
  <h1><%= @ticker %></h1>
  <!-- Your content -->
</div>
```

### Customizing Styles

Edit `public/css/style.css`:

```css
:root {
  --primary-color: #2196F3;  /* Change primary color */
}
```

## Troubleshooting

### TA-Lib Errors

```
Error: libta-lib.so: cannot open shared object file
```

**Solution:** Install TA-Lib library (see Installation section)

### Redis Connection Errors

```
Error: Could not connect to Redis
```

**Solution:** Start Redis server: `redis-server`

### Stock Data Not Loading

```
Error: Failed to load data for TICKER
```

**Solutions:**
1. Check API key is set: `echo $AV_API_KEY`
2. Verify ticker symbol is valid
3. Check internet connection
4. Try a different ticker

### Port Already in Use

```
Error: Address already in use - bind(2)
```

**Solution:** Kill the process using port 4567 or change the port in `app.rb`

## Performance Tips

1. **Enable Caching** - Cache API responses to reduce load times
2. **Use Alpha Vantage** - More reliable than Yahoo Finance
3. **Limit Historical Data** - Use shorter time periods for faster loading
4. **Optimize Charts** - Reduce data points for better rendering performance

## Security Notes

⚠️ **Educational Use Only** - This application is for educational purposes.

**Security Considerations:**
- API keys in environment variables (never commit to git)
- Input validation on ticker symbols
- Rate limiting for API endpoints (recommended for production)
- HTTPS for production deployments
- CSRF protection for form submissions

## Contributing

Improvements welcome! Areas for contribution:

- [ ] Portfolio optimization interface
- [ ] Pattern discovery visualization
- [ ] Genetic programming UI
- [ ] Real-time streaming dashboard
- [ ] Multi-stock comparison
- [ ] Export data to CSV/PDF
- [ ] Dark mode toggle
- [ ] User authentication
- [ ] Saved watchlists

## License

MIT License - Same as SQA library

## Credits

- **SQA Library** - Stock analysis framework
- **Plotly.js** - Interactive charts
- **Sinatra** - Web framework
- **TA-Lib** - Technical analysis
- **Font Awesome** - Icons

## Links

- [SQA Repository](https://github.com/MadBomber/sqa)
- [Plotly.js Documentation](https://plotly.com/javascript/)
- [Sinatra Documentation](http://sinatrarb.com/)
- [TA-Lib](http://ta-lib.org/)

---

**Disclaimer:** This software is for educational and research purposes only. Do not use for actual trading without proper due diligence. The authors are not responsible for financial losses.
