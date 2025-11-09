# SQA Rails Application

A comprehensive Rails 7.1 web application for stock market technical analysis using the SQA library. Features interactive charts, strategy backtesting, and market analysis with a modern, responsive UI.

## Features

### 📊 Interactive Dashboard
- Candlestick & line charts with Plotly.js
- Volume analysis with color-coded bars
- Technical indicators (RSI, MACD, SMA, EMA, Bollinger Bands)
- Key metrics cards (52-week high/low, RSI, market regime)
- Real-time price information
- Strategy comparison

### 🤖 Strategy Backtesting
- 6 built-in strategies (RSI, MACD, SMA, EMA, Bollinger Bands, KBS)
- Detailed performance metrics
- Strategy comparison and ranking
- Visual strategy selection
- Comprehensive backtest results

### 📈 Market Analysis
- Market regime detection (bull/bear/sideways)
- Seasonal pattern analysis
- FPOP (Future Period) analysis
- Risk metrics (VaR, Sharpe ratio, max drawdown)

### 🎨 Modern Rails UI
- Responsive design
- MVC architecture
- RESTful API endpoints
- Rails 7.1 conventions
- Turbo & Stimulus ready

## Installation

### Prerequisites

- Ruby >= 3.2
- Rails >= 7.1
- SQLite3
- TA-Lib library
- Redis (for KBS)

### Install TA-Lib

**macOS:**
```bash
brew install ta-lib
```

**Ubuntu/Debian:**
```bash
sudo apt-get install ta-lib-dev
```

### Install Dependencies

```bash
cd examples/rails_app
bundle install
```

### Database Setup

```bash
rails db:create
rails db:migrate
```

### Set Up API Keys

```bash
export AV_API_KEY="your_api_key_here"
```

Get a free API key from [Alpha Vantage](https://www.alphavantage.co/support/#api-key)

### Start Redis

```bash
redis-server
```

## Usage

### Start the Application

```bash
rails server
```

Or using bin/rails:
```bash
./bin/rails server
```

The application will start on `http://localhost:3000`

### Navigate the App

1. **Home Page** (`/`) - Landing page with quick links
2. **Dashboard** (`/dashboard/:ticker`) - Interactive charts and metrics
3. **Analysis** (`/analyze/:ticker`) - Market analysis and insights
4. **Backtest** (`/backtest/:ticker`) - Strategy backtesting interface
5. **Portfolio** (`/portfolio`) - Portfolio optimization (coming soon)

## Rails Structure

```
rails_app/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── dashboard_controller.rb
│   │   ├── analysis_controller.rb
│   │   ├── backtest_controller.rb
│   │   ├── portfolio_controller.rb
│   │   └── api/
│   │       └── v1/
│   │           └── stocks_controller.rb     # API endpoints
│   ├── views/
│   │   ├── layouts/
│   │   │   └── application.html.erb          # Main layout
│   │   ├── dashboard/
│   │   │   ├── index.html.erb                # Home page
│   │   │   └── show.html.erb                 # Stock dashboard
│   │   ├── analysis/
│   │   │   └── show.html.erb                 # Analysis page
│   │   ├── backtest/
│   │   │   └── show.html.erb                 # Backtest page
│   │   ├── portfolio/
│   │   │   └── index.html.erb                # Portfolio page
│   │   └── errors/
│   │       └── show.html.erb                 # Error page
│   └── assets/
│       ├── stylesheets/
│       │   └── application.css               # Main stylesheet
│       └── javascripts/
│           └── application.js                # Main JavaScript
├── config/
│   ├── application.rb                        # App configuration
│   ├── boot.rb                               # Boot configuration
│   ├── environment.rb                        # Environment setup
│   ├── database.yml                          # Database config
│   └── routes.rb                             # Routes definition
├── db/                                       # Database files
├── public/                                   # Static files
├── bin/
│   └── rails                                 # Rails script
├── Gemfile                                   # Ruby dependencies
├── config.ru                                 # Rack config
└── README.md                                 # This file
```

## Routes

| Route | Method | Controller#Action | Description |
|-------|--------|-------------------|-------------|
| `/` | GET | `dashboard#index` | Home page |
| `/dashboard/:ticker` | GET | `dashboard#show` | Stock dashboard |
| `/analyze/:ticker` | GET | `analysis#show` | Market analysis |
| `/backtest/:ticker` | GET | `backtest#show` | Strategy backtesting |
| `/portfolio` | GET | `portfolio#index` | Portfolio optimization |
| `/api/v1/stock/:ticker` | GET | `api/v1/stocks#show` | Get stock data |
| `/api/v1/indicators/:ticker` | GET | `api/v1/stocks#indicators` | Get indicators |
| `/api/v1/backtest/:ticker` | POST | `api/v1/stocks#backtest` | Run backtest |
| `/api/v1/analyze/:ticker` | GET | `api/v1/stocks#analyze` | Get analysis |
| `/api/v1/compare/:ticker` | POST | `api/v1/stocks#compare` | Compare strategies |

## API Endpoints

### GET /api/v1/stock/:ticker

Returns stock price data with OHLCV (Open, High, Low, Close, Volume).

**Example:**
```bash
curl http://localhost:3000/api/v1/stock/AAPL
```

**Response:**
```json
{
  "ticker": "AAPL",
  "current_price": 175.50,
  "change": 2.30,
  "change_percent": 1.33,
  "high_52w": 198.23,
  "low_52w": 124.17,
  "dates": ["2023-01-01", ...],
  "open": [170.0, ...],
  "high": [172.0, ...],
  "low": [169.5, ...],
  "close": [171.0, ...],
  "volume": [50000000, ...]
}
```

### GET /api/v1/indicators/:ticker

Returns calculated technical indicators.

**Example:**
```bash
curl http://localhost:3000/api/v1/indicators/AAPL
```

### POST /api/v1/backtest/:ticker

Runs a backtest for the specified strategy.

**Example:**
```bash
curl -X POST http://localhost:3000/api/v1/backtest/AAPL \
  -H "Content-Type: application/json" \
  -d '{"strategy":"RSI"}'
```

### GET /api/v1/analyze/:ticker

Returns market analysis including regime, seasonal patterns, FPOP, and risk metrics.

### POST /api/v1/compare/:ticker

Compares all available strategies and returns results sorted by return.

## Technology Stack

### Backend
- **Rails 7.1** - Full-stack web framework
- **SQLite3** - Database
- **Puma** - Web server
- **SQA Library** - Stock analysis and backtesting
- **TA-Lib** - Technical analysis indicators
- **Polars** - High-performance DataFrames
- **Redis** - KBS blackboard persistence

### Frontend
- **Plotly.js** - Interactive financial charts
- **Turbo** - Single-page application speed
- **Stimulus** - JavaScript framework
- **Font Awesome** - Icons
- **Custom CSS3** - Responsive styling

## Development

### Rails Console

```bash
rails console
```

### Run Tests

```bash
rails test
```

### Database Operations

```bash
rails db:create    # Create database
rails db:migrate   # Run migrations
rails db:reset     # Reset database
```

### Check Routes

```bash
rails routes
```

## Configuration

### Environment Variables

- `AV_API_KEY` - Alpha Vantage API key
- `RAILS_ENV` - Rails environment (development/production/test)
- `RAILS_MAX_THREADS` - Maximum threads (default: 5)

### Database

Edit `config/database.yml` to configure database settings.

### Asset Pipeline

Assets are automatically compiled in development. For production:

```bash
rails assets:precompile
```

## Deployment

### Using Rails Server

```bash
rails server -e production -p 3000
```

### Using Puma

```bash
puma -C config/puma.rb
```

### Using Docker

```dockerfile
FROM ruby:3.3
WORKDIR /app
COPY Gemfile* ./
RUN bundle install
COPY . .
RUN rails assets:precompile
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
```

## Troubleshooting

### TA-Lib Not Found

```bash
# Reinstall TA-Lib
brew reinstall ta-lib  # macOS
sudo apt-get install --reinstall ta-lib-dev  # Ubuntu
```

### Redis Connection Error

```bash
# Start Redis
redis-server &
```

### Database Issues

```bash
# Reset database
rails db:reset
```

### Port Already in Use

```bash
# Kill process on port 3000
lsof -ti:3000 | xargs kill -9
```

## Differences from Sinatra App

| Feature | Sinatra App | Rails App |
|---------|-------------|-----------|
| Framework | Lightweight | Full-featured |
| Structure | Flat | MVC architecture |
| Routing | Manual | Rails conventions |
| Database | Optional | Built-in (SQLite) |
| Asset Pipeline | Manual | Sprockets |
| ORM | None | Active Record |
| Testing | Manual | Built-in (Minitest) |
| Generators | None | Rails generators |
| Conventions | Minimal | Rails conventions |

## Performance Tips

1. **Enable Caching** - Use Rails caching for API responses
2. **Database Indexes** - Add indexes for frequently queried fields
3. **Asset Compression** - Use asset minification in production
4. **CDN** - Serve static assets from CDN
5. **Background Jobs** - Use Sidekiq for long-running tasks

## Security

- CSRF protection enabled
- API authentication recommended for production
- Environment variables for sensitive data
- Input validation on ticker symbols
- HTTPS recommended for production

## Contributing

Improvements welcome! Areas for contribution:

- [ ] Portfolio optimization interface
- [ ] User authentication and sessions
- [ ] Saved watchlists
- [ ] Real-time WebSocket updates
- [ ] Background job processing
- [ ] API rate limiting
- [ ] Caching layer
- [ ] Additional strategies

## License

MIT License - Same as SQA library

## Credits

- **SQA Library** - Stock analysis framework
- **Rails** - Web framework
- **Plotly.js** - Interactive charts
- **TA-Lib** - Technical analysis
- **Font Awesome** - Icons

## Links

- [SQA Repository](https://github.com/MadBomber/sqa)
- [Rails Documentation](https://guides.rubyonrails.org/)
- [Plotly.js Documentation](https://plotly.com/javascript/)
- [TA-Lib](http://ta-lib.org/)

---

**Disclaimer:** This software is for educational and research purposes only. Do not use for actual trading without proper due diligence. The authors are not responsible for financial losses.
