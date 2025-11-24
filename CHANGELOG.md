## [Unreleased]

## [0.0.39] - 2025-11-24

### Added
- **YARD Documentation Examples**:
  - Added comprehensive usage examples to 15+ critical methods across core classes
  - `SQA::Portfolio`: Examples for `#buy`, `#sell`, `#value`, `#summary` methods
  - `SQA::Backtest`: Examples for `#run` method showing RSI strategy, custom date ranges, and equity curve access
  - `SQA::Stock`: Examples for `#update` method with API metadata fetching
  - `SQA::DataFrame`: Examples for `#concat_and_deduplicate!` and `#to_csv` methods
  - All examples demonstrate real-world usage with expected outputs

- **File Formats Documentation**:
  - Created comprehensive `docs/file_formats.md` documenting all CSV and JSON formats
  - **Portfolio Positions CSV**: Schema and usage for `save_to_csv()` / `load_from_csv()`
  - **Trade History CSV**: Schema and usage for `save_trades_to_csv()`
  - **Stock Data CSV**: OHLCV format with critical TA-Lib ordering requirements
  - **Stock Metadata JSON**: Company overview data structure
  - **Configuration Files**: YAML/TOML format documentation
  - Added to MkDocs navigation under User Guide > Core Concepts

### Changed
- **API Documentation Improvements**:
  - Regenerated all 51+ API reference markdown files with new examples
  - Examples now appear in purple Material Design admonition boxes
  - Improved discoverability of common usage patterns

## [0.0.38] - 2025-11-24

### Added
- **Integrated YARD Documentation into MkDocs**:
  - Created `bin/generate_api_docs.rb` script to convert YARD comments to markdown
  - Generates 51+ API reference markdown files in `docs/api-reference/`
  - Unified Material theme across all documentation pages
  - Auto-generated documentation includes timestamp and complete class/module information

### Changed
- **Enhanced Documentation Formatting**:
  - Markdown generation now uses Material Design admonitions (note, info, success, example)
  - Added emojis for visual hierarchy (📦 classes, 🔧 modules, 🏭 class methods, 🔨 instance methods, 📝 attributes, 🔢 constants)
  - Parameters displayed in formatted tables instead of lists
  - Return values in green success boxes with type badges
  - Usage examples in purple example boxes with proper syntax highlighting
  - Collapsible source location sections to reduce visual clutter
  - Attribute access indicators (🔄 read/write, 👁️ read-only, ✍️ write-only)

- **Simplified Rake Tasks**:
  - Consolidated documentation tasks under `docs:` namespace
  - `docs:build` - Generate API markdown from YARD + build MkDocs site
  - `docs:serve` - Serve documentation locally with live reload
  - `docs:clean` - Clean generated documentation files
  - `docs:deploy` - Deploy to GitHub Pages
  - Removed legacy tasks: `yard`, `yard_server`, `api_docs`

- **Documentation Visual Improvements**:
  - Updated `docs/index.md` with flexbox layout (logo left, features right)
  - Converted 6 mermaid diagrams to colorful SVG images with transparent backgrounds
  - High-contrast colors for better readability
  - Added namespace icons (🎯 SQA, 📊 strategies) in API index

### Dependencies
- Added `yard` and `yard-markdown` gems for API documentation generation

## [0.0.36] - 2025-11-24

### Changed
- **Phase 3 Architecture & Design Improvements**:
  - Added deprecation warning for auto-initialization at require time (will be removed in v1.0)
    - Added `SQA::Config.initialized?` class method to track initialization state
    - Warning only shows when `$VERBOSE` is set
  - `concat_and_deduplicate!` now enforces ascending order for TA-Lib compatibility
    - Warns and forces `descending: false` if `descending: true` is passed
    - Prevents silent calculation errors from incorrect data ordering
  - Extracted Faraday connection to configurable dependency in `SQA::Stock`
    - Added `ALPHA_VANTAGE_URL` constant
    - Added class methods: `connection`, `connection=`, `default_connection`, `reset_connection!`
    - Allows injection of custom connections for testing/mocking
    - Deprecated `CONNECTION` constant (will be removed in v1.0)

### Added
- **Test Coverage for Phase 3**:
  - Added 2 tests to `test/config_test.rb` for `initialized?` method
  - Added 7 tests to `test/stock_test.rb` for configurable connection
  - Updated `test/data_frame_test.rb` to verify ascending order enforcement

## [0.0.35] - 2025-11-23

### Changed
- **Phase 2 Code Quality & Best Practices**:
  - Replaced class variables (`@@var`) with class instance variables (`@var`) for thread safety
    - `SQA::init.rb`: `@@config`, `@@av_api_key` → `@config`, `@av_api_key`
    - `SQA::Ticker`: Restructured with `class << self` block, added `reset!` method
    - `SQA::Stock`: `@@top` → `@top`, added `reset_top!` method
  - Replaced `puts` statements with `debug_me` in `SQA::SectorAnalyzer`
  - Simplified `method_missing` in `SQA::DataFrame` (no longer dynamically defines methods)
  - Fixed type checking pattern in `SQA::Strategy#add` to use `is_a?` instead of `.class ==`
  - Fixed `SQA::Strategy#available` to use `.name` instead of `.to_s` (avoids pretty_please gem conflict)
  - Removed magic placeholder "xyzzy" from `SQA::Stock#create_data`

### Fixed
- **DataFrame.from_aofh**: Fixed Polars compatibility by converting to hash-of-arrays format
- **DataFrame.from_aofh**: Now properly passes `mapping:` and `transformers:` parameters
- **Ticker.valid?**: Now handles nil and empty string inputs gracefully
- **Ticker.lookup**: Now handles nil and empty string inputs gracefully

### Added
- **Test Coverage for Phase 2**:
  - New `test/ticker_test.rb` with 10 tests for Ticker class
  - New `test/strategy_test.rb` with 10 tests for Strategy class
  - Added 4 tests to `test/data_frame_test.rb` for `from_aofh` and `method_missing`
  - Added 2 tests to `test/stock_test.rb` for `reset_top!` method

## [0.0.34] - 2025-11-23

### Fixed
- **Test Suite**: Fixed 15+ pre-existing test failures
  - Fixed typo in RiskManagerTest (`var` → `cvar`)
  - Fixed Portfolio test expectations (total_cost, P&L calculation, summary keys)
  - Fixed URL trailing slash comparisons in AlphaVantage/YahooFinance tests
  - Fixed FPOP test expectation (implementation returns partial windows)
  - Fixed SectorAnalyzer symbol/string comparison
  - Fixed AlphaVantage header mapping test (timestamp, no adjusted_close)
- **PatternMatcher**: Fixed integer division bug in `pattern_quality` method
  - Added `.to_f` conversion to prevent truncation with integer inputs
- **Config Coercion**: Fixed string-to-symbol coercion for `log_level` and `plotting_library`
  - Added explicit `coerce_key` handlers

### Added
- **Portfolio**: Added `commission` to `attr_accessor` for public access
- **Error Namespacing**: Added `SQA::BadParameterError` namespace with backwards-compatible alias

### Changed
- **Phase 1 Security & Correctness** (from improvement plan):
  - Replaced shell injection vulnerability (`touch` backticks → `FileUtils.touch`)
  - Replaced deprecated `has_key?` with `key?` across codebase
  - Added `SQA::DataFetchError` and `SQA::ConfigurationError` exception classes
  - Replaced bare `rescue` clauses with specific exception types

## [0.0.33] - 2025-11-23

### Removed
- **Sinatra Example App**: Removed `examples/sinatra_app/` directory
  - Functionality moved to separate gem: [sqa_demo-sinatra](https://github.com/MadBomber/sqa_demo-sinatra)
  - Cleaner separation between library and demo application

### Added
- **Documentation**: Added links to sqa_demo-sinatra demo application
  - Updated README.md with Web Demo Application section
  - Updated docs/index.md with Demo Application section
  - Updated examples/README.md with reference to web demo
- **LLM Documentation**: Added llms.txt for AI assistant compatibility
- **Improvement Plan**: Added docs/IMPROVEMENT_PLAN.md for upcoming code quality improvements

## [0.0.32] - 2024-11-12

### Added
- **CSV Updates**: Conditional CSV updates based on timestamp
  - Only updates CSV files when new data is available
  - Improves performance by avoiding unnecessary writes

### Changed
- **DataFrame**: Removed debug_me calls from SQA::DataFrame
  - Cleaned up debugging code for production use

### Fixed
- **CSV Data Quality**: Multiple improvements to CSV data handling
  - Change CSV sort order to ascending (oldest-first) for TA-Lib compatibility
  - Prevent duplicate timestamps in CSV data files
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
