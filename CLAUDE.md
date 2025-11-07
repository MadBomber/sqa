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
- **SQA::Strategy**: Trading strategy framework with built-in strategies
- **SQA::Portfolio**: Portfolio management (minimal implementation)
- **SQA::Ticker**: Stock symbol validation and lookup
- **SQA::Config**: Configuration management with YAML/TOML support

### Data Flow
1. Create `SQA::Stock` with ticker symbol
2. Stock fetches data from Alpha Vantage or Yahoo Finance
3. Data stored in Polars-based `SQA::DataFrame`
4. Apply technical indicators via `SQAI` / `SQA::TAI` (from sqa-tai gem)
5. Execute trading strategies to generate buy/sell/hold signals
6. Analyze results with statistical functions

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

## File Structure

```
lib/
├── api/
│   └── alpha_vantage_api.rb       # Alpha Vantage API client (462 lines)
├── patches/
│   └── string.rb                   # String helpers (camelize, constantize, underscore)
└── sqa/
    ├── config.rb                   # Configuration management
    ├── data_frame.rb               # Polars DataFrame wrapper
    ├── data_frame/
    │   ├── alpha_vantage.rb        # Alpha Vantage data adapter
    │   └── yahoo_finance.rb        # Yahoo Finance scraper
    ├── errors.rb                   # Error classes
    ├── gp.rb                       # Genetic programming (experimental)
    ├── indicator.rb                # Delegates to sqa-tai gem
    ├── init.rb                     # Module initialization
    ├── portfolio.rb                # Portfolio management (minimal)
    ├── stock.rb                    # Stock class with data management
    ├── strategy.rb                 # Strategy framework
    ├── strategy/
    │   ├── common.rb               # Shared strategy utilities
    │   ├── consensus.rb            # Consensus from multiple strategies
    │   ├── ema.rb                  # EMA-based strategy
    │   ├── mp.rb                   # Market Profile strategy
    │   ├── mr.rb                   # Mean Reversion strategy
    │   ├── random.rb               # Random signals (testing)
    │   ├── rsi.rb                  # RSI-based strategy
    │   └── sma.rb                  # SMA-based strategy
    ├── ticker.rb                   # Ticker validation
    └── version.rb                  # Version constant
```

## Common Gotchas

1. **DataFrame vs Polars**: `df` is SQA::DataFrame, `df.data` is Polars::DataFrame
2. **Indicators need Arrays**: Extract data with `.to_a` before passing to indicators
3. **No CLI commands**: Previous CLI functionality has been removed
4. **Indicators in separate gem**: Technical indicators are in `sqa-tai`, not SQA
5. **API key format changed**: Use `AV_API_KEY` not `AV_API_KEYS` (singular)
6. **Strategies need OpenStruct**: Pass data to strategies as OpenStruct with named fields

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
