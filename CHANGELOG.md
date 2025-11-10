## [Unreleased]

### Fixed
- **DataFrame::Data**: Added missing `SQA::DataFrame::Data` class for stock metadata storage
  - Stores ticker, name, exchange, source, indicators, and overview data
  - Supports both hash initialization (JSON) and keyword arguments
  - Used by `SQA::Stock` for persisting stock metadata
  - Fixes error when loading stocks in sqa-cli gem

## [0.0.31] - 2024-11-09

### Added
- **FPOP Module**: Future Period of Performance analysis utilities for calculating future period loss/profit
- Comprehensive FPL (Future Period Loss/Profit) analysis utilities

### Fixed
- Use correct KBS DSL syntax with 'perform' instead of 'then'
- KBS syntax corrections and improvements

## [0.0.30] - 2024-11-08

### Added
- **StrategyGenerator**: Reverse-engineer profitable trades to discover patterns
  - Pattern mining from historical data
  - Strategy generation from discovered patterns
  - Comprehensive tests and documentation

## [0.0.29] - 2024-11-07

### Added
- **GeneticProgram**: Evolutionary algorithm for strategy parameter optimization
- **KBS Strategy**: RETE-based forward-chaining inference engine (454 lines)
- **Stream**: Real-time price streaming with callback support (343 lines)
- Comprehensive tests for all new modules

## [0.0.28] - 2024-11-06

### Added
- **Portfolio**: Position and trade tracking with P&L calculations (265 lines)
- **Backtest**: Strategy simulation with comprehensive performance metrics (345 lines)
- **4 New Strategies**:
  - Bollinger Bands strategy
  - MACD crossover strategy
  - Stochastic oscillator strategy
  - Volume Breakout strategy

## [0.0.27] - 2024-11-05

### Changed
- **BREAKING**: Renamed `bin/sqa` to `bin/sqa-console` for clarity

### Removed
- Removed `api_key_manager` dependency (unused)

### Documentation
- Updated README.md and CLAUDE.md to reflect current capabilities

## [0.0.26] - 2024-11-04

### Changed
- **BREAKING**: Replaced local indicator implementations with `sqa-tai` gem
  - All 150+ technical indicators now provided by separate sqa-tai gem
  - sqa-tai wraps TA-Lib C library (industry standard)
  - Access via `SQAI.indicator_name(prices, options)` or `SQA::TAI.indicator_name(...)`

### Removed
- Local indicator implementations (migrated to sqa-tai gem)

## [0.0.25] - 2024-11-03

### Changed
- **BREAKING**: Refactored SQA::DataFrame to integrate with polars-df gem
  - Replaced previous DataFrame implementation with high-performance Polars-backed version
  - 30x performance improvement for time series operations
  - Wraps Polars::DataFrame with convenience methods

### Added
- Documentation for architecture refactoring plan
- Conventional Commits specification document

### Chore
- Pruned unused gems from Gemfile
- Updated Gemfile.lock dependencies

## [0.0.24] - 2023-11-08

- replaced [tty-option gem](https://github.com/piotrmurach/tty-option) with [dry-cli gem](https://github.com/dry-rb/dry-cli)

## [0.0.1] - 2023-08-10

- Planting the Flag
