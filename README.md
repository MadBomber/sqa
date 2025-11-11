# SQA - Simple Qualitative Analysis

[![Badges?](https://img.shields.io/badge/Badge-We%20don't%20need%20no%20stinkin'%20badges!-red)](https://www.youtube.com/watch?v=VqomZQMZQCQ)

A Ruby library for technical analysis of stock market data. This is a simplistic set of tools for quantitative and qualitative stock analysis designed for **educational purposes only**.

**⚠️ WARNING:** This is a learning tool, not production software. Do NOT use this library when real money is at stake. The BUY/SELL signals it generates should not be taken seriously. If you lose your shirt playing in the stock market, don't come crying to me. Playing in the market is like playing in the street - you're going to get run over.

<!-- Tocer[start]: Auto-generated, don't remove. -->

## Table of Contents

  - [Features](#features)
  - [Installation](#installation)
  - [Configuration](#configuration)
    - [Data Directory](#data-directory)
    - [Alpha Vantage API Key](#alpha-vantage-api-key)
  - [Usage](#usage)
    - [Working with Stocks](#working-with-stocks)
    - [DataFrame Operations](#dataframe-operations)
    - [Technical Indicators](#technical-indicators)
    - [Trading Strategies](#trading-strategies)
    - [Statistics](#statistics)
  - [Interactive Console](#interactive-console)
  - [Architecture](#architecture)
  - [Data Sources](#data-sources)
    - [Alpha Vantage](#alpha-vantage)
    - [Yahoo Finance](#yahoo-finance)
  - [Contributing](#contributing)
  - [License](#license)

<!-- Tocer[finish]: Auto-generated, don't remove. -->

## Features

### Core Capabilities
- **High-Performance DataFrames** - Polars-based data structures for time series financial data
- **150+ Technical Indicators** - Via the separate [`sqa-tai`](https://github.com/MadBomber/sqa-tai) gem (TA-Lib wrapper)
- **Trading Strategies** - Framework for building and testing trading strategies
- **Multiple Data Sources** - Alpha Vantage and Yahoo Finance adapters
- **Stock Management** - Track stocks with historical prices and company metadata
- **Statistical Analysis** - Comprehensive statistics on price data
- **Ticker Validation** - Validate stock symbols against market exchanges
- **Interactive Console** - IRB console for experimentation (`sqa-console`)
- **CLI Tools** - Command-line interface via the separate [`sqa-cli`](https://github.com/MadBomber/sqa-cli) gem

### Advanced Features
- **Portfolio Management** - Track positions, trades, P&L with commission support
- **Backtesting Framework** - Simulate trading strategies with comprehensive performance metrics
- **Strategy Generator** - Reverse-engineer profitable trades to discover indicator patterns
- **Genetic Programming** - Evolve optimal strategy parameters through natural selection
- **Knowledge-Based Strategy (KBS)** - RETE-based forward-chaining inference for complex trading rules
- **Real-Time Streaming** - Event-driven live price processing with on-the-fly signal generation
- **FPL Analysis** - Future Period Loss/Profit analysis with risk metrics and directional classification
- **Market Regime Detection** - Identify bull/bear/sideways markets with volatility and strength metrics
- **Seasonal Analysis** - Discover calendar-dependent patterns (monthly/quarterly performance)
- **Sector Analysis** - Multi-stock pattern discovery with KBS blackboards per sector
- **Walk-Forward Validation** - Time-series cross-validation to prevent pattern overfitting
- **Pattern Context System** - Context-aware patterns that know when/where they're valid

## Installation

Install the gem:

```bash
gem install sqa
```

This will automatically install the `sqa-tai` gem (technical indicators) as a dependency.

Or add to your `Gemfile`:

```ruby
gem 'sqa'
```

Then run:

```bash
bundle install
```

For command-line tools, install the separate CLI gem:

```bash
gem install sqa-cli
```

## Configuration

### Data Directory

SQA stores historical price data and metadata in a data directory. By default, it uses `~/sqa_data/`:

```ruby
require 'sqa'

# Initialize with default configuration
SQA.init

# Or specify a custom data directory
SQA::Config.new(data_dir: '~/Documents/my_stock_data')
```

Create your data directory:

```bash
mkdir ~/sqa_data
```

### Alpha Vantage API Key

SQA uses Alpha Vantage for stock data. You'll need a free API key from [https://www.alphavantage.co/](https://www.alphavantage.co/)

Set the environment variable:

```bash
export AV_API_KEY="your_api_key_here"
# or
export ALPHAVANTAGE_API_KEY="your_api_key_here"
```

The free tier allows:
- 5 API calls per minute
- 100 API calls per day

## Usage

### Working with Stocks

```ruby
require 'sqa'

# Initialize SQA
SQA.init

# Create or load a stock (automatically fetches/updates data from Alpha Vantage)
aapl = SQA::Stock.new(ticker: 'AAPL', source: :alpha_vantage)
#=> aapl with 1207 data points from 2019-01-02 to 2023-10-17

# Access the DataFrame
aapl.df
#=> SQA::DataFrame (wraps Polars::DataFrame)

# Get column names
aapl.df.columns
#=> ["timestamp", "open_price", "high_price", "low_price", "close_price", "adj_close_price", "volume"]

# Access price data
aapl.df["adj_close_price"]
#=> Polars::Series with all adjusted closing prices

# Get recent prices
prices = aapl.df["adj_close_price"].to_a
prices.last(5)
#=> [179.8, 180.71, 178.85, 178.72, 177.15]

# Access company metadata
aapl.name
#=> "Apple Inc."

aapl.exchange
#=> "NASDAQ"

aapl.overview
#=> Hash with detailed company information
```

### DataFrame Operations

SQA::DataFrame is a wrapper around the high-performance Polars DataFrame:

```ruby
require 'sqa'

# Create from hash
data = {
  timestamp: ['2023-01-01', '2023-01-02', '2023-01-03'],
  price: [100.0, 101.5, 99.8]
}
df = SQA::DataFrame.new(data)

# Load from CSV
df = SQA::DataFrame.load(source: 'aapl.csv')

# Basic operations
df.size        # Number of rows
df.ncols       # Number of columns
df.to_h        # Convert to hash
df.to_csv('output.csv')  # Save to CSV

# Access underlying Polars DataFrame
df.data        # Polars::DataFrame
```

### Technical Indicators

All technical indicators are provided by the separate [`sqa-tai`](https://github.com/MadBomber/sqa-tai) gem, which wraps the industry-standard TA-Lib library. The `sqa-tai` gem must be installed separately but is automatically included as a dependency of `sqa`.

```ruby
require 'sqa'

prices = [100, 102, 105, 103, 107, 110, 108, 112, 115, 113]

# Simple Moving Average
sma = SQAI.sma(prices, period: 5)
#=> [104.0, 105.4, 106.6, 108.0, 110.4, 111.6]

# Relative Strength Index
rsi = SQAI.rsi(prices, period: 14)
#=> [70.5, 68.2, ...]

# Exponential Moving Average
ema = SQAI.ema(prices, period: 5)
#=> [...]

# Bollinger Bands (returns upper, middle, lower)
upper, middle, lower = SQAI.bbands(prices, period: 5)

# MACD
macd, signal, histogram = SQAI.macd(prices, fast_period: 12, slow_period: 26, signal_period: 9)

# Many more indicators available!
# See: https://github.com/MadBomber/sqa-tai
```

**Available Indicators:** SMA, EMA, WMA, RSI, MACD, Bollinger Bands, Stochastic, ADX, ATR, CCI, Williams %R, ROC, Momentum, and 140+ more via TA-Lib.

### Trading Strategies

Build and test trading strategies:

```ruby
require 'sqa'
require 'ostruct'

# Load strategies
strategies = SQA::Strategy.new
strategies.auto_load  # Loads all built-in strategies

# Add specific strategies
strategies.add SQA::Strategy::RSI
strategies.add SQA::Strategy::SMA
strategies.add SQA::Strategy::EMA

# Prepare data for strategy execution
prices = aapl.df["adj_close_price"].to_a
rsi_value = SQAI.rsi(prices, period: 14).last

vector = OpenStruct.new
vector.rsi = rsi_value
vector.prices = prices

# Execute strategies
results = strategies.execute(vector)
#=> [:hold, :buy, :hold]  # One result per strategy

# Built-in strategies:
# - SQA::Strategy::RSI - Based on Relative Strength Index
# - SQA::Strategy::SMA - Simple Moving Average crossover
# - SQA::Strategy::EMA - Exponential Moving Average crossover
# - SQA::Strategy::MACD - MACD crossover strategy
# - SQA::Strategy::BollingerBands - Bollinger Bands bounce strategy
# - SQA::Strategy::Stochastic - Stochastic oscillator strategy
# - SQA::Strategy::VolumeBreakout - Volume-based breakout strategy
# - SQA::Strategy::MR - Mean Reversion
# - SQA::Strategy::MP - Market Profile
# - SQA::Strategy::KBS - Knowledge-based RETE strategy (advanced)
# - SQA::Strategy::Random - Random signal generator (for testing)
# - SQA::Strategy::Consensus - Combines multiple strategies
```

### Statistics

Comprehensive statistical analysis on price data (via `lite-statistics` gem):

```ruby
require 'sqa'

prices = [179.8, 180.71, 178.85, 178.72, 177.15]

stats = prices.summary
#=> {
#     max: 180.71,
#     min: 177.15,
#     mean: 179.046,
#     median: 178.85,
#     mode: nil,
#     range: 3.56,
#     sample_standard_deviation: 1.19,
#     sample_variance: 1.42,
#     ...
#   }
```

### Portfolio Management

Track positions, trades, and P&L:

```ruby
require 'sqa'

# Create portfolio with initial cash and commission
portfolio = SQA::Portfolio.new(initial_cash: 10_000.0, commission: 1.0)

# Buy stock
portfolio.buy('AAPL', shares: 10, price: 150.0, date: Date.today)

# Sell stock
portfolio.sell('AAPL', shares: 5, price: 160.0, date: Date.today)

# Check portfolio value
current_prices = { 'AAPL' => 165.0 }
portfolio.value(current_prices)
#=> Total portfolio value

# Calculate profit/loss
portfolio.profit_loss(current_prices)
#=> P&L amount

# View summary
portfolio.summary
#=> { initial_cash: 10000.0, cash: 8248.0, positions: 1, trades: 2, ... }

# Save trades to CSV
portfolio.save_to_csv('my_trades.csv')

# Load from CSV
portfolio.load_from_csv('my_trades.csv')
```

### Backtesting

Simulate trading strategies against historical data:

```ruby
require 'sqa'

SQA.init
stock = SQA::Stock.new(ticker: 'AAPL')

# Create backtest
backtest = SQA::Backtest.new(
  stock: stock,
  strategy: SQA::Strategy::RSI,
  initial_capital: 10_000.0,
  commission: 1.0
)

# Run backtest
results = backtest.run

# View comprehensive metrics
puts "Total Return: #{results.total_return.round(2)}%"
puts "Annualized Return: #{results.annualized_return.round(2)}%"
puts "Sharpe Ratio: #{results.sharpe_ratio.round(2)}"
puts "Max Drawdown: #{results.max_drawdown.round(2)}%"
puts "Total Trades: #{results.total_trades}"
puts "Win Rate: #{results.win_rate.round(2)}%"
puts "Profit Factor: #{results.profit_factor.round(2)}"

# Access equity curve for charting
results.equity_curve  #=> Array of portfolio values over time
```

### Strategy Generator

Reverse-engineer profitable trades to discover winning patterns:

```ruby
require 'sqa'

SQA.init
stock = SQA::Stock.new(ticker: 'AAPL')

# Create strategy generator
generator = SQA::StrategyGenerator.new(
  stock: stock,
  min_gain_percent: 10.0,    # Find trades with ≥10% gain
  holding_period: (5..20)    # Within 5-20 days
)

# Discover patterns
patterns = generator.discover_patterns(min_pattern_frequency: 3)

# Print discovered patterns
generator.print_patterns(max_patterns: 10)
#=> Pattern #1:
#=>   Frequency: 15 occurrences
#=>   Average Gain: 12.5%
#=>   Average Holding: 8.3 days
#=>   Conditions:
#=>     - rsi: oversold
#=>     - macd_crossover: bullish
#=>     - volume: high

# Generate strategy from top pattern
strategy = generator.generate_strategy(pattern_index: 0, strategy_type: :class)

# Backtest the discovered strategy
backtest = SQA::Backtest.new(stock: stock, strategy: strategy)
results = backtest.run

# Export patterns to CSV
generator.export_patterns('/tmp/patterns.csv')
```

### Genetic Programming

Evolve optimal strategy parameters through natural selection:

```ruby
require 'sqa'

SQA.init
stock = SQA::Stock.new(ticker: 'AAPL')

# Create genetic program
gp = SQA::GeneticProgram.new(
  stock: stock,
  population_size: 50,
  generations: 100,
  mutation_rate: 0.15
)

# Define parameter space to explore
gp.define_genes(
  rsi_period: (7..30).to_a,
  buy_threshold: (20..40).to_a,
  sell_threshold: (60..80).to_a
)

# Define fitness function (backtest performance)
gp.fitness do |genes|
  # Create strategy with these genes
  strategy = create_rsi_strategy(genes)

  # Backtest and return total return as fitness
  backtest = SQA::Backtest.new(stock: stock, strategy: strategy)
  backtest.run.total_return
end

# Evolve!
best = gp.evolve

puts "Best Parameters:"
puts "  RSI Period: #{best.genes[:rsi_period]}"
puts "  Buy Threshold: #{best.genes[:buy_threshold]}"
puts "  Sell Threshold: #{best.genes[:sell_threshold]}"
puts "  Fitness: #{best.fitness.round(2)}%"

# View evolution history
gp.history.each do |gen|
  puts "Gen #{gen[:generation]}: Best=#{gen[:best_fitness].round(2)}%"
end
```

### Knowledge-Based Strategy (KBS)

Build sophisticated rule-based systems with RETE forward chaining:

```ruby
require 'sqa'

# Create KBS strategy
strategy = SQA::Strategy::KBS.new(load_defaults: false)

# Define custom trading rules
strategy.add_rule :golden_opportunity do
  desc "Perfect storm: Multiple bullish indicators align"

  # Multiple conditions
  on :rsi, { level: :oversold }
  on :macd, { crossover: :bullish }
  on :stochastic, { zone: :oversold, crossover: :bullish }
  on :trend, { short_term: :up, strength: :strong }
  on :volume, { level: :high }

  # Negation: Don't buy if overbought elsewhere
  without :rsi, { level: :overbought }

  # Action
  then do
    assert(:signal, { action: :buy, confidence: :high })
  end
end

# Execute strategy
signal = strategy.execute(vector)
#=> :buy or :sell or :hold

# Use with backtesting
backtest = SQA::Backtest.new(
  stock: stock,
  strategy: SQA::Strategy::KBS,
  initial_capital: 10_000.0
)
results = backtest.run
```

### Real-Time Streaming

Process live stock prices and generate on-the-fly trading signals:

```ruby
require 'sqa'

# Create stream processor
stream = SQA::Stream.new(
  ticker: 'AAPL',
  window_size: 100,
  strategies: [
    SQA::Strategy::RSI,
    SQA::Strategy::MACD,
    SQA::Strategy::BollingerBands
  ]
)

# Register signal callback
stream.on_signal do |signal, data|
  puts "🔔 SIGNAL: #{signal.upcase}"
  puts "   Price: $#{data[:price]}"
  puts "   Consensus: #{data[:strategies_vote]}"

  # Execute trade, send alert, etc.
  execute_trade(signal, data) if signal != :hold
end

# Register update callback (optional)
stream.on_update do |data|
  puts "📊 Price update: $#{data[:price]}"
end

# Feed live data (from WebSocket, API, etc.)
stream.update(
  price: 150.25,
  volume: 1_000_000,
  timestamp: Time.now
)

# Access real-time indicators
rsi = stream.indicator(:rsi, period: 14)
sma = stream.indicator(:sma, period: 20)

# View stream statistics
stream.stats
#=> { ticker: 'AAPL', updates: 125, current_price: 150.25, ... }
```

### FPL Analysis (Future Period Loss/Profit)

Analyze potential future price movements with risk metrics:

```ruby
require 'sqa'

stock = SQA::Stock.new(ticker: 'AAPL')

# Calculate FPL for 14-day future period
fpl_data = stock.df.fpl(fpop: 14)
# Returns: [[min_delta, max_delta], ...] for each price point

# Full analysis with risk metrics
analysis = stock.df.fpl_analysis(fpop: 14)

analysis.first
#=> {
#  min_delta: -5.2,      # Worst loss percentage
#  max_delta: 8.7,       # Best gain percentage
#  risk: 13.9,           # Volatility (max - min)
#  direction: :UNCERTAIN,# :UP, :DOWN, :UNCERTAIN, :FLAT
#  magnitude: 1.75,      # Average expected movement
#  interpretation: "UNCERTAIN: 1.75% (±6.95% risk)"
#}

# Filter high-quality opportunities
good_indices = SQA::FPOP.filter_by_quality(
  analysis,
  min_magnitude: 5.0,     # Minimum average movement
  max_risk: 10.0,         # Maximum acceptable volatility
  directions: [:UP]       # Only bullish patterns
)

# Use with Strategy Generator for risk-aware pattern discovery
generator = SQA::StrategyGenerator.new(
  stock: stock,
  min_gain_percent: 10.0,
  fpop: 10,
  max_fpl_risk: 20.0,           # NEW: Filter high-volatility points
  required_fpl_directions: [:UP] # NEW: Only bullish patterns
)
```

**Key Benefits:**
- Captures both upside AND downside potential
- Measures volatility/risk during future period
- Classifies directional bias (UP/DOWN/UNCERTAIN/FLAT)
- Enables risk-adjusted opportunity filtering

### Market Regime Detection

Identify and adapt to changing market conditions:

```ruby
# Detect current market regime
regime = SQA::MarketRegime.detect(stock)
#=> {
#  type: :bull,           # :bull, :bear, :sideways
#  volatility: :low,      # :low, :medium, :high
#  strength: :strong,     # :weak, :moderate, :strong
#  lookback_days: 60,
#  detected_at: 2024-11-08
#}

# Analyze regime history
regimes = SQA::MarketRegime.detect_history(stock)
#=> [
#  { type: :bull, start_index: 0, end_index: 120, duration: 120 },
#  { type: :bear, start_index: 121, end_index: 200, duration: 79 },
#  ...
#]

# Split data by regime
regime_data = SQA::MarketRegime.split_by_regime(stock)
#=> {
#  bull: [{ prices: [...], start_index: 0, end_index: 120 }, ...],
#  bear: [...],
#  sideways: [...]
#}

# Use regime-specific strategies
current_regime = SQA::MarketRegime.detect(stock)
strategy = case current_regime[:type]
when :bull
  SQA::Strategy::MomentumBreakout
when :bear
  SQA::Strategy::MeanReversion
when :sideways
  SQA::Strategy::BollingerBands
end
```

**Key Benefits:**
- Different strategies for different market conditions
- Avoid using bull market strategies in bear markets
- Detect regime changes before they impact performance

### Seasonal Analysis

Discover calendar-dependent patterns:

```ruby
# Analyze seasonal performance
seasonal = SQA::SeasonalAnalyzer.analyze(stock)
#=> {
#  best_months: [10, 11, 12],        # October, November, December
#  worst_months: [5, 6, 7],          # May, June, July
#  best_quarters: [4, 1],            # Q4 and Q1
#  worst_quarters: [2, 3],
#  has_seasonal_pattern: true,
#  monthly_returns: { ... },
#  quarterly_returns: { ... }
#}

# Filter data for Q4 only (holiday shopping season)
q4_data = SQA::SeasonalAnalyzer.filter_by_quarters(stock, [4])
#=> { indices: [...], dates: [...], prices: [...] }

# Filter for specific months
dec_data = SQA::SeasonalAnalyzer.filter_by_months(stock, [12])

# Get context for specific date
context = SQA::SeasonalAnalyzer.context_for_date(Date.new(2024, 12, 15))
#=> {
#  month: 12,
#  quarter: 4,
#  month_name: "December",
#  quarter_name: "Q4",
#  is_year_end: true,
#  is_holiday_season: true,
#  is_earnings_season: false
#}

# Discover patterns only for best months
generator = SQA::StrategyGenerator.new(stock: stock)
patterns = generator.discover_context_aware_patterns(
  analyze_seasonal: true
)

patterns.each do |pattern|
  puts pattern.context.valid_months  # [10, 11, 12] for Q4 patterns
end
```

**Real-World Examples:**
- Retail stocks: Q4 holiday shopping boost
- Tax prep stocks: Q1/Q4 seasonal surge
- Energy stocks: Summer driving season
- Agriculture stocks: Planting/harvest cycles

### Sector Analysis with KBS

Analyze patterns across related stocks using KBS blackboards:

```ruby
# Create sector analyzer (separate blackboard per sector)
analyzer = SQA::SectorAnalyzer.new

# Add stocks to technology sector
analyzer.add_stock('AAPL', sector: :technology)
analyzer.add_stock('MSFT', sector: :technology)
analyzer.add_stock('GOOGL', sector: :technology)

# Detect sector-wide regime
tech_stocks = [
  SQA::Stock.new(ticker: 'AAPL'),
  SQA::Stock.new(ticker: 'MSFT'),
  SQA::Stock.new(ticker: 'GOOGL')
]

sector_regime = analyzer.detect_sector_regime(:technology, tech_stocks)
#=> {
#  sector: :technology,
#  consensus_regime: :bull,  # Majority vote
#  sector_strength: 85.0,    # % of stocks bullish
#  stock_regimes: [...]
#}

# Discover patterns across entire sector
sector_patterns = analyzer.discover_sector_patterns(
  :technology,
  tech_stocks,
  min_gain_percent: 10.0,
  fpop: 10
)

# Patterns that work for MULTIPLE stocks in sector
sector_patterns.each do |sp|
  puts "Pattern found in: #{sp[:stocks].join(', ')}"
  puts "Avg gain: #{sp[:avg_gain].round(2)}%"
  puts "Conditions: #{sp[:conditions]}"
end

# Query sector blackboard
facts = analyzer.query_sector(:technology, :sector_pattern)

# Print sector summary
analyzer.print_sector_summary(:technology)
```

**Available Sectors:**
`:technology`, `:finance`, `:healthcare`, `:energy`, `:consumer`, `:industrial`, `:materials`, `:utilities`, `:real_estate`, `:communications`

**Key Benefits:**
- Leverage "stocks move together" in same sector
- Find patterns valid across multiple related stocks
- Persistent KBS blackboard tracks sector knowledge
- Cross-stock pattern validation

### Walk-Forward Validation

Prevent overfitting with time-series cross-validation:

```ruby
generator = SQA::StrategyGenerator.new(
  stock: stock,
  min_gain_percent: 10.0,
  fpop: 10
)

# Run walk-forward validation
results = generator.walk_forward_validate(
  train_size: 250,  # 1 year training window
  test_size: 60,    # 3 months testing window
  step_size: 30     # Step forward 1 month each iteration
)

# Only patterns that work out-of-sample
validated_patterns = results[:validated_patterns]

# Detailed results for each iteration
results[:validation_results].each do |r|
  puts "Train: #{r[:train_period]}"
  puts "Test:  #{r[:test_period]}"
  puts "Return: #{r[:test_return]}%"
  puts "Sharpe: #{r[:test_sharpe]}"
end

# Statistics
all_returns = results[:validation_results].map { |r| r[:test_return] }
avg_return = all_returns.sum / all_returns.size
puts "Average out-of-sample return: #{avg_return.round(2)}%"
```

**How It Works:**
1. Split data into train/test windows
2. Discover patterns on training data
3. Test patterns on future (unseen) data
4. Roll forward and repeat
5. Only keep patterns that work out-of-sample

**Prevents:**
- Curve-fitting to historical noise
- Patterns that only worked in the past
- Overconfidence in backtest results

### Pattern Context System

Context-aware patterns that know when/where they're valid:

```ruby
# Discover patterns with full context
generator = SQA::StrategyGenerator.new(stock: stock, min_gain_percent: 10.0)

patterns = generator.discover_context_aware_patterns(
  analyze_regime: true,
  analyze_seasonal: true,
  sector: :technology
)

# Each pattern has rich context metadata
pattern = patterns.first
pattern.context.market_regime        #=> :bull
pattern.context.volatility_regime    #=> :low
pattern.context.valid_months         #=> [10, 11, 12]
pattern.context.valid_quarters       #=> [4, 1]
pattern.context.sector               #=> :technology
pattern.context.discovered_period    #=> "2020-01-01 to 2022-12-31"

# Runtime validation - check if pattern applies NOW
valid = pattern.context.valid_for?(
  date: Date.today,
  regime: :bull,
  sector: :technology
)

if valid
  # Execute strategy - context matches current conditions
  signal = strategy.trade(vector)
else
  # Skip - pattern not valid in current context
  puts "Pattern not valid for current conditions"
end

# Pattern summary includes context
puts pattern.to_s
#=> "Pattern(conditions=3, freq=12, gain=11.5%, success=75.0%) [bull months:10,11,12 technology]"
```

**Context Metadata:**
- **Market regime**: Bull/bear/sideways classification
- **Seasonality**: Valid months/quarters
- **Sector**: Industry classification
- **Volatility regime**: Low/medium/high
- **Discovery period**: When pattern was found
- **Stability score**: Consistency over time

**Key Benefits:**
- Patterns aren't universal - they're context-specific
- Avoid using patterns in wrong market conditions
- Seasonal awareness (Q4 retail patterns, etc.)
- Sector-specific strategies
- Runtime validation before execution

## Interactive Console

Launch an interactive Ruby console with SQA loaded:

```bash
sqa-console
```

This opens IRB with the SQA library pre-loaded, allowing you to experiment interactively:

```ruby
# Already loaded: require 'sqa'

SQA.init
stock = SQA::Stock.new(ticker: 'MSFT')
prices = stock.df["close_price"].to_a
sma = SQAI.sma(prices, period: 20)
```

## Examples

The `examples/` directory contains comprehensive demonstrations of advanced features:

- **`genetic_programming_example.rb`** - Evolve RSI parameters through natural selection
- **`kbs_strategy_example.rb`** - Build rule-based trading systems with RETE
- **`realtime_stream_example.rb`** - Process live price streams with callbacks
- **`strategy_generator_example.rb`** - Mine profitable patterns from history

Run examples:
```bash
ruby examples/genetic_programming_example.rb
ruby examples/strategy_generator_example.rb
```

See `examples/README.md` for detailed documentation and integration patterns.

## Architecture

**Core Components:**

- **`SQA::DataFrame`** - High-performance Polars-based data container for time series
- **`SQA::Stock`** - Represents a stock with price history and metadata
- **`SQA::Ticker`** - Stock symbol validation and lookup
- **`SQA::Strategy`** - Trading strategy execution framework
- **`SQA::Config`** - Configuration management
- **`SQAI`** - Alias for `SQA::TAI` (technical indicators from sqa-tai gem)

**Advanced Components:**

- **`SQA::Portfolio`** - Position and trade tracking with P&L calculations
- **`SQA::Backtest`** - Strategy simulation with comprehensive metrics
- **`SQA::StrategyGenerator`** - Pattern mining from profitable historical trades
- **`SQA::GeneticProgram`** - Evolutionary algorithm for parameter optimization
- **`SQA::Strategy::KBS`** - RETE-based forward-chaining inference engine
- **`SQA::Stream`** - Real-time price stream processor with event callbacks

**Data Flow:**

1. Create `SQA::Stock` with ticker symbol
2. Stock fetches data from Alpha Vantage or Yahoo Finance
3. Data stored in Polars-based `SQA::DataFrame`
4. Apply technical indicators via `SQAI` / `SQA::TAI`
5. Execute trading strategies to generate signals
6. Analyze results with statistical functions

**Design Patterns:**

- Plugin architecture for indicators and strategies
- Data source abstraction (Alpha Vantage, Yahoo Finance)
- Delegation to Polars for DataFrame operations
- Configuration hierarchy: defaults < environment variables < config file

## Data Sources

### Alpha Vantage

**Recommended data source** with a well-documented API.

- **URL:** [https://www.alphavantage.co/](https://www.alphavantage.co/)
- **API Key:** Required (free tier available)
- **Environment Variable:** `AV_API_KEY` or `ALPHAVANTAGE_API_KEY`
- **Rate Limits:** 5 calls/minute, 100 calls/day (free tier)

```ruby
stock = SQA::Stock.new(ticker: 'GOOGL', source: :alpha_vantage)
```

### Yahoo Finance

**No API available** - uses web scraping for historical data.

- **URL:** [https://finance.yahoo.com/](https://finance.yahoo.com/)
- **Manual Download:** Download CSV files and place in `SQA.data_dir`
- **Filename Format:** `ticker.csv` (lowercase), e.g., `aapl.csv`

To manually download:
1. Visit [https://finance.yahoo.com/quote/AAPL/history?p=AAPL](https://finance.yahoo.com/quote/AAPL/history?p=AAPL)
2. Download historical data as CSV
3. Move to your data directory as `aapl.csv`

```ruby
stock = SQA::Stock.new(ticker: 'AAPL', source: :yahoo_finance)
```

## Contributing

Contributions are welcome! Got an idea for a new indicator or strategy? Want to improve the math or signals?

- **Bug reports and pull requests:** [https://github.com/MadBomber/sqa](https://github.com/MadBomber/sqa)
- **Technical indicators:** Contribute to [sqa-tai](https://github.com/MadBomber/sqa-tai)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

---

**Remember:** This is an educational tool. Historical performance is not an indicator of future results. Never use this for real trading decisions.
