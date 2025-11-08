# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SQA (Simple Qualitative Analysis) is a Ruby library for stock market technical analysis designed for educational purposes. It provides high-performance data structures, trading strategies, and integrates with the `sqa-tai` gem for 150+ technical indicators.

**Important:** SQA is a **library-only gem** with no CLI functionality. The `sqa-console` executable launches an IRB console for interactive experimentation.

## Common Development Commands

### Running Tests
```bash
rake test           # Run unit tests with Minitest
just test          # Alternative: Run tests via justfile
just coverage      # Run tests and open coverage report
```

### Building and Installing
```bash
rake install       # Install gem locally
just install       # Install with TOC update and man page generation
rake build         # Build gem package
```

### Code Quality
```bash
just flay          # Static code analysis for duplication
```

### Documentation
```bash
rake toc           # Update README table of contents
rake man           # Generate man pages
```

### Interactive Console
```bash
sqa-console        # Launch IRB with SQA library loaded
```

## Architecture Overview

### Core Module Structure
- **SQA::Stock**: Primary domain object representing a stock with price history and metadata
- **SQA::DataFrame**: High-performance wrapper around Polars for time series data manipulation
- **SQAI / SQA::TAI**: Access to 150+ technical indicators from `sqa-tai` gem (TA-Lib wrapper)
- **SQA::Strategy**: Trading strategy framework with 12+ built-in strategies
- **SQA::Portfolio**: Position and trade tracking with P&L calculations (265 lines)
- **SQA::Backtest**: Strategy simulation with comprehensive performance metrics (345 lines)
- **SQA::Ticker**: Stock symbol validation and lookup
- **SQA::Config**: Configuration management with YAML/TOML support

### Advanced Module Structure
- **SQA::StrategyGenerator**: Reverse-engineer profitable trades to discover patterns (690 lines, enhanced with Pattern Context)
- **SQA::GeneticProgram**: Evolutionary algorithm for strategy parameter optimization (259 lines)
- **SQA::Strategy::KBS**: RETE-based forward-chaining inference engine (454 lines)
- **SQA::Stream**: Real-time price stream processor with callbacks (343 lines)
- **SQA::FPOP**: Future Period Loss/Profit analysis utilities (243 lines)
- **SQA::MarketRegime**: Bull/bear/sideways market detection with volatility analysis (176 lines)
- **SQA::SeasonalAnalyzer**: Calendar-dependent pattern discovery (monthly/quarterly) (185 lines)
- **SQA::SectorAnalyzer**: Cross-stock analysis with KBS blackboards per sector (242 lines)

### Data Flow

**Basic Flow:**
1. Create `SQA::Stock` with ticker symbol
2. Stock fetches data from Alpha Vantage or Yahoo Finance
3. Data stored in Polars-based `SQA::DataFrame`
4. Apply technical indicators via `SQAI` / `SQA::TAI` (from sqa-tai gem)
5. Execute trading strategies to generate buy/sell/hold signals
6. Analyze results with statistical functions

**Advanced Workflows:**

**Backtesting:**
1. Load historical data via `SQA::Stock`
2. Create `SQA::Backtest` with stock, strategy, and capital
3. Backtest simulates trades using `SQA::Portfolio`
4. Returns `Results` with metrics: Sharpe ratio, max drawdown, win rate, etc.

**Pattern Discovery:**
1. `SQA::StrategyGenerator` scans historical data for profitable points
2. Identifies indicator states at each profitable entry
3. Mines patterns from indicator combinations
4. Generates executable strategies from patterns
5. Strategies can be backtested or used live

**Parameter Optimization:**
1. `SQA::GeneticProgram` defines parameter space (genes)
2. Creates random population of strategies
3. Evaluates fitness via backtesting
4. Evolves through selection, crossover, mutation
5. Returns best individual with optimal parameters

**Real-Time Trading:**
1. `SQA::Stream` receives live price updates
2. Maintains rolling window of recent data
3. Calculates indicators on-the-fly (with caching)
4. Executes multiple strategies in parallel
5. Aggregates signals and fires callbacks
6. Callbacks can execute trades, send alerts, log data

**FPL Analysis:**
1. `SQA::FPOP.fpl(prices, fpop: 10)` calculates min/max future deltas
2. `SQA::FPOP.fpl_analysis(prices, fpop: 10)` adds risk metrics and direction
3. `SQA::FPOP.filter_by_quality()` filters by magnitude, risk, direction
4. Integration with `StrategyGenerator` via `max_fpl_risk` parameter
5. DataFrame convenience methods: `df.fpl()` and `df.fpl_analysis()`

**Market Regime Analysis:**
1. `SQA::MarketRegime.detect(stock)` classifies current market
2. Returns regime type (bull/bear/sideways), volatility, and strength
3. `detect_history(stock)` identifies regime changes over time
4. `split_by_regime(stock)` groups data by regime periods
5. Enables regime-specific strategy selection

**Seasonal Pattern Discovery:**
1. `SQA::SeasonalAnalyzer.analyze(stock)` finds calendar patterns
2. Identifies best/worst months and quarters
3. `detect_seasonality()` determines if patterns are significant
4. `filter_by_months()` and `filter_by_quarters()` extract seasonal data
5. Enables time-of-year pattern validation

**Sector Analysis:**
1. `SQA::SectorAnalyzer` creates KBS blackboard per sector
2. Stocks registered with sector classification
3. `discover_sector_patterns()` finds cross-stock patterns
4. `detect_sector_regime()` gets consensus market view
5. Persistent SQLite storage for each sector's knowledge base

**Context-Aware Pattern Discovery:**
1. `StrategyGenerator.discover_context_aware_patterns()` adds metadata
2. Patterns tagged with market regime, valid months/quarters, sector
3. `PatternContext.valid_for?(date, regime, sector)` runtime validation
4. `walk_forward_validate()` prevents overfitting with out-of-sample testing
5. Patterns know when they should and shouldn't be used

### Key Design Patterns
- **Plugin Architecture**: Strategies are pluggable modules
- **Data Source Abstraction**: Multiple data providers (Alpha Vantage, Yahoo Finance) with common interface
- **Delegation Pattern**: DataFrame delegates to Polars for high-performance operations
- **Configuration Hierarchy**: defaults < environment variables < config file

## Important Implementation Notes

### Data Sources
- **Alpha Vantage API** requires `AV_API_KEY` or `ALPHAVANTAGE_API_KEY` environment variable
- **Yahoo Finance** scraping available as fallback (no API, less reliable)
- CSV file imports supported for historical data (place in data directory as `ticker.csv`)

### Configuration
- Config files: YAML or TOML in `~/.sqa.*`
- Data directory: `~/sqa_data/` (default, configurable)
- Environment variables:
  - `AV_API_KEY` or `ALPHAVANTAGE_API_KEY` - Alpha Vantage API key
  - Custom config via `SQA::Config.new(data_dir: '...')`

### DataFrame Implementation
- Uses `polars-df` gem (Rust-backed, blazingly fast)
- Wraps Polars::DataFrame with convenience methods
- Custom statistics via `lite-statistics` gem monkey patches on Arrays
- **Always** prefer column-based operations over row iterations for performance
- Access underlying Polars DataFrame via `.data` attribute

### Technical Indicators
- **All indicators** provided by separate `sqa-tai` gem
- `sqa-tai` wraps TA-Lib C library (industry standard)
- Access via `SQAI.indicator_name(prices, options)` or `SQA::TAI.indicator_name(...)`
- 150+ indicators available: SMA, EMA, RSI, MACD, Bollinger Bands, ADX, ATR, etc.
- See: https://github.com/MadBomber/sqa-tai

### Testing Approach
- Minitest framework in `/test/` directory
- SimpleCov for coverage reporting
- Test data fixtures in `test/test_helper.rb`
- **Note:** Indicator tests may need updates after migrating to sqa-tai (different return values)

## Development Guidelines

### When Adding New Strategies
1. Create new file in `lib/sqa/strategy/`
2. Define class under `SQA::Strategy::` namespace
3. Implement `self.trade(vector)` class method
4. Return `:buy`, `:sell`, or `:hold`
5. Add corresponding test in `test/strategy/`

**Example:**
```ruby
class SQA::Strategy::MyStrategy
  def self.trade(vector)
    # vector is an OpenStruct with indicator values
    if vector.rsi < 30
      :buy
    elsif vector.rsi > 70
      :sell
    else
      :hold
    end
  end
end
```

### Working with DataFrames
- Use Polars native operations when possible (accessed via `df.data`)
- Avoid Ruby loops over rows for performance
- Leverage vectorized operations
- Example: `df.data["close_price"]` returns Polars::Series

### Working with Indicators
- **Do NOT add indicators to SQA** - contribute to `sqa-tai` gem instead
- Use indicators: `SQAI.sma(prices_array, period: 20)`
- All indicators work on Ruby Arrays, not DataFrames
- Extract price array first: `prices = stock.df["close_price"].to_a`

### API Integration
- New data sources go in `lib/sqa/data_frame/`
- Follow existing adapter pattern (see `alpha_vantage.rb` and `yahoo_finance.rb`)
- Handle rate limiting and errors gracefully
- Return Polars-compatible data structures

### Adding New Data Sources
1. Create `lib/sqa/data_frame/my_source.rb`
2. Define class `SQA::DataFrame::MySource`
3. Implement `self.recent(ticker, **options)` method
4. Return data in format compatible with Polars::DataFrame
5. Add mapping for column names if needed

## Critical Constraints

- This is an **EDUCATIONAL tool** - maintain clear disclaimers
- Do NOT remove financial risk warnings from README or docs
- **No CLI** - this is a library, not a command-line application
- Performance matters - prefer vectorized DataFrame operations
- Maintain backward compatibility with existing data file formats
- API keys from environment variables only (no api_key_manager)

### Testing Guidelines
- All new features should have corresponding tests in `/test/`
- Integration tests require `RUN_INTEGRATION_TESTS=1` environment variable
- Use `skip` for tests requiring network access or long runtimes
- Portfolio, Backtest, Stream have comprehensive test coverage
- GP and StrategyGenerator tests available but skipped by default (long running)

## File Structure

```
lib/
├── api/
│   └── alpha_vantage_api.rb       # Alpha Vantage API client (462 lines)
├── patches/
│   └── string.rb                   # String helpers (camelize, constantize, underscore)
└── sqa/
    ├── backtest.rb                 # ✨ NEW: Backtesting framework (345 lines)
    ├── config.rb                   # Configuration management
    ├── data_frame.rb               # Polars DataFrame wrapper
    ├── data_frame/
    │   ├── alpha_vantage.rb        # Alpha Vantage data adapter
    │   └── yahoo_finance.rb        # Yahoo Finance scraper
    ├── errors.rb                   # Error classes
    ├── fpop.rb                     # ✨ NEW: Future Period Loss/Profit analysis (243 lines)
    ├── gp.rb                       # ✨ NEW: Genetic programming (259 lines, COMPLETE)
    ├── indicator.rb                # Delegates to sqa-tai gem
    ├── init.rb                     # Module initialization
    ├── market_regime.rb            # ✨ NEW: Market regime detection (176 lines)
    ├── portfolio.rb                # ✨ NEW: Portfolio management (265 lines, COMPLETE)
    ├── seasonal_analyzer.rb        # ✨ NEW: Seasonal pattern discovery (185 lines)
    ├── sector_analyzer.rb          # ✨ NEW: Sector analysis with KBS (242 lines)
    ├── stock.rb                    # Stock class with data management
    ├── strategy.rb                 # Strategy framework
    ├── strategy/
    │   ├── bollinger_bands.rb      # ✨ NEW: Bollinger Bands strategy
    │   ├── common.rb               # Shared strategy utilities
    │   ├── consensus.rb            # Consensus from multiple strategies
    │   ├── ema.rb                  # EMA-based strategy
    │   ├── kbs_strategy.rb         # ✨ NEW: RETE-based KBS (454 lines)
    │   ├── macd.rb                 # ✨ NEW: MACD crossover strategy
    │   ├── mp.rb                   # Market Profile strategy
    │   ├── mr.rb                   # Mean Reversion strategy
    │   ├── random.rb               # Random signals (testing)
    │   ├── rsi.rb                  # RSI-based strategy
    │   ├── sma.rb                  # SMA-based strategy
    │   ├── stochastic.rb           # ✨ NEW: Stochastic oscillator strategy
    │   └── volume_breakout.rb      # ✨ NEW: Volume breakout strategy
    ├── stream.rb                   # ✨ NEW: Real-time price streaming (343 lines)
    ├── strategy_generator.rb       # ✨ NEW: Pattern discovery (690 lines)
    ├── ticker.rb                   # Ticker validation
    └── version.rb                  # Version constant

examples/
├── README.md                       # ✨ NEW: Comprehensive examples guide
├── fpop_analysis_example.rb        # ✨ NEW: FPL analysis utilities (191 lines)
├── genetic_programming_example.rb  # ✨ NEW: GP parameter evolution
├── kbs_strategy_example.rb         # ✨ NEW: RETE rule-based trading
├── pattern_context_example.rb      # ✨ NEW: Context-aware patterns (280 lines)
├── realtime_stream_example.rb      # ✨ NEW: Live price processing
└── strategy_generator_example.rb   # ✨ NEW: Pattern mining

test/
├── backtest_test.rb                # ✨ NEW: Backtest tests
├── fpop_test.rb                    # ✨ NEW: FPL analysis tests (154 lines)
├── gp_test.rb                      # ✨ NEW: Genetic programming tests
├── market_regime_test.rb           # ✨ NEW: Market regime tests (165 lines)
├── pattern_context_test.rb         # ✨ NEW: Pattern context tests (177 lines)
├── pattern_context_integration_test.rb  # ✨ NEW: Integration tests (342 lines)
├── portfolio_test.rb               # ✨ NEW: Portfolio tests
├── seasonal_analyzer_test.rb       # ✨ NEW: Seasonal analysis tests (203 lines)
├── sector_analyzer_test.rb         # ✨ NEW: Sector analysis tests (162 lines)
├── stream_test.rb                  # ✨ NEW: Stream processor tests
├── strategy_generator_test.rb      # ✨ NEW: Strategy generator tests
├── data_frame_test.rb              # DataFrame tests
├── test_helper.rb                  # Test configuration
└── indicator/                      # Indicator tests (legacy, may need updates)
```

**Line Counts:**
- Core: ~2,000 lines (DataFrame, Stock, Strategy framework)
- Advanced: ~3,150 lines (Portfolio, Backtest, GP, KBS, Stream, Generator, FPOP, Pattern Context)
- Tests: ~2,000 lines (including Pattern Context integration tests)
- Examples: ~1,850 lines (including FPL and Pattern Context examples)
- Total: ~9,000 lines

## Common Gotchas

1. **DataFrame vs Polars**: `df` is SQA::DataFrame, `df.data` is Polars::DataFrame
2. **Indicators need Arrays**: Extract data with `.to_a` before passing to indicators
3. **No CLI commands**: Previous CLI functionality has been removed
4. **Indicators in separate gem**: Technical indicators are in `sqa-tai`, not SQA
5. **API key format changed**: Use `AV_API_KEY` not `AV_API_KEYS` (singular)
6. **Strategies need OpenStruct**: Pass data to strategies as OpenStruct with named fields

## Advanced Features Quick Reference

### Portfolio Management
```ruby
portfolio = SQA::Portfolio.new(initial_cash: 10_000, commission: 1.0)
portfolio.buy('AAPL', shares: 10, price: 150.0)
portfolio.sell('AAPL', shares: 5, price: 160.0)
portfolio.value({ 'AAPL' => 165.0 })
```

### Backtesting
```ruby
backtest = SQA::Backtest.new(stock: stock, strategy: SQA::Strategy::RSI)
results = backtest.run
puts "Return: #{results.total_return}%, Sharpe: #{results.sharpe_ratio}"
```

### Strategy Generator
```ruby
gen = SQA::StrategyGenerator.new(stock: stock, min_gain_percent: 10.0)
patterns = gen.discover_patterns
strategy = gen.generate_strategy(pattern_index: 0)
```

### Genetic Programming
```ruby
gp = SQA::GeneticProgram.new(stock: stock, population_size: 50)
gp.define_genes(rsi_period: (7..30).to_a)
gp.fitness { |genes| backtest_with(genes).total_return }
best = gp.evolve
```

### Knowledge-Based Strategy
```ruby
strategy = SQA::Strategy::KBS.new(load_defaults: false)
strategy.add_rule :my_rule do
  on :rsi, { level: :oversold }
  on :macd, { crossover: :bullish }
  perform { assert(:signal, { action: :buy }) }
end
```

### Real-Time Streaming
```ruby
stream = SQA::Stream.new(ticker: 'AAPL', strategies: [SQA::Strategy::RSI])
stream.on_signal { |signal, data| execute_trade(signal, data) }
stream.update(price: 150.25, volume: 1_000_000)
```

### FPL Analysis
```ruby
# Basic FPL calculation
prices = stock.df["adj_close_price"].to_a
fpl_data = SQA::FPOP.fpl(prices, fpop: 10)
# => [[min_delta, max_delta], ...]

# Comprehensive analysis
analysis = SQA::FPOP.fpl_analysis(prices, fpop: 10)
puts "Risk: #{analysis[:risk]}%, Direction: #{analysis[:direction]}"

# Filter high-quality opportunities
filtered = SQA::FPOP.filter_by_quality(
  analysis,
  min_magnitude: 5.0,
  max_risk: 25.0,
  directions: [:UP]
)
```

### Market Regime Detection
```ruby
# Detect current regime
regime = SQA::MarketRegime.detect(stock)
puts "Regime: #{regime[:type]}"  # => :bull, :bear, or :sideways
puts "Volatility: #{regime[:volatility]}"  # => :low, :medium, :high

# Get regime history
history = SQA::MarketRegime.detect_history(stock, window: 60)

# Split data by regime
splits = SQA::MarketRegime.split_by_regime(stock)
bull_periods = splits[:bull]
```

### Seasonal Analysis
```ruby
# Analyze seasonal patterns
seasonal = SQA::SeasonalAnalyzer.analyze(stock)
puts "Best months: #{seasonal[:best_months]}"  # => [10, 11, 12]
puts "Best quarters: #{seasonal[:best_quarters]}"  # => [4, 1]

# Filter for Q4 only
q4_data = SQA::SeasonalAnalyzer.filter_by_quarters(stock, [4])
```

### Sector Analysis
```ruby
analyzer = SQA::SectorAnalyzer.new
analyzer.add_stock('AAPL', sector: :technology)
analyzer.add_stock('MSFT', sector: :technology)

# Detect sector regime
tech_stocks = ['AAPL', 'MSFT'].map { |t| SQA::Stock.new(ticker: t) }
regime = analyzer.detect_sector_regime(:technology, tech_stocks)

# Find sector-wide patterns
patterns = analyzer.discover_sector_patterns(:technology, tech_stocks)
```

### Context-Aware Pattern Discovery
```ruby
# Discover patterns with context
generator = SQA::StrategyGenerator.new(stock: stock, fpop: 10)
patterns = generator.discover_context_aware_patterns(
  analyze_regime: true,
  analyze_seasonal: true,
  sector: :technology
)

# Walk-forward validation
validated = generator.walk_forward_validate(
  train_size: 250,
  test_size: 60
)

# Runtime validation
pattern = patterns.first
valid = pattern.context.valid_for?(
  date: Date.today,
  regime: :bull,
  sector: :technology
)
```

## Quick Reference

```ruby
require 'sqa'

# Initialize
SQA.init

# Load stock data
stock = SQA::Stock.new(ticker: 'AAPL')

# Get price array
prices = stock.df["adj_close_price"].to_a

# Calculate indicators
sma = SQAI.sma(prices, period: 20)
rsi = SQAI.rsi(prices, period: 14)

# Execute strategies
require 'ostruct'
vector = OpenStruct.new(rsi: rsi.last, prices: prices)

strategy = SQA::Strategy.new
strategy.add SQA::Strategy::RSI
signals = strategy.execute(vector)  # => [:buy, :sell, :hold]
```
