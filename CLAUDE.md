# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SQA (Simple Qualitative Analysis) is a Ruby gem for stock market technical analysis designed for educational purposes. It uses a modular plugin architecture with technical indicators and trading strategies.

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

### CLI Usage
```bash
sqa --help                    # Show help
sqa -c ~/.sqa.yml            # Use specific config file
sqa analysis                 # Run portfolio analysis
```

## Architecture Overview

### Core Module Structure
- **SQA::Stock**: Primary domain object representing a stock with price history
- **SQA::DataFrame**: Wrapper around polars-df for data manipulation
- **SQA::Indicator**: Base module for 20+ technical indicators (RSI, SMA, EMA, MACD, etc.)
- **SQA::Strategy**: Trading strategy implementations using indicators
- **SQA::Portfolio**: Portfolio management with trades tracking

### Data Flow
1. Data sources (AlphaVantage/Yahoo) fetch price data
2. DataFrame processes and stores time series data
3. Indicators calculate technical analysis metrics
4. Strategies generate trading signals
5. Portfolio tracks positions and trades

### Key Design Patterns
- **Plugin Architecture**: Indicators and strategies are pluggable modules
- **Configuration Hierarchy**: CLI args > config file > environment > defaults
- **Data Source Abstraction**: Multiple data providers with common interface
- **Builder Pattern**: Complex data transformations in DataFrame

## Important Implementation Notes

### Data Sources
- AlphaVantage API requires `AV_API_KEY` environment variable
- Yahoo Finance scraping available as fallback (less reliable)
- CSV file imports supported for historical data

### Configuration
- Config files: YAML, JSON, or TOML in `~/.sqa.*`
- Data directory: `~/sqa_data/` (default)
- Environment variables: `SQA_*` prefix for overrides

### DataFrame Implementation
- Recently migrated to `polars-df` gem for performance
- Custom statistics via `lite-statistics` gem monkey patches
- Column-based operations preferred over row iterations

### Testing Approach
- Minitest framework in `/test/` directory
- SimpleCov for coverage reporting
- Test data fixtures in `test/test_helper.rb`

## Development Guidelines

### When Adding New Indicators
1. Create new file in `lib/sqa/indicator/`
2. Include `SQA::Indicator` module
3. Define `call` class method accepting DataFrame
4. Add corresponding test in `test/indicator/`

### When Adding New Strategies
1. Create new file in `lib/sqa/strategy/`
2. Inherit from base strategy class
3. Implement signal generation logic
4. Add portfolio backtesting support

### Working with DataFrames
- Use polars-df native operations when possible
- Avoid Ruby loops over rows for performance
- Leverage vectorized operations

### API Integration
- New data sources go in `lib/sqa/data_frame/`
- Follow existing adapter pattern
- Handle rate limiting and errors gracefully

## Critical Constraints

- This is an EDUCATIONAL tool - maintain clear disclaimers
- Do NOT remove financial risk warnings
- Performance matters - prefer vectorized DataFrame operations
- Maintain backward compatibility with existing portfolio formats