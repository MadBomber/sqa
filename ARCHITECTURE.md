# SQA Project - Refactoring Architecture Plan

**Date:** 2025-01-05
**Session:** claude/review-codebase-planning-011CUqHdDz75cZMoeGXq8XfR

## Executive Summary

The SQA project is being refactored from a monolithic gem into a modular 3-gem architecture:

1. **sqa-talib** - Pure indicator library (TA-Lib wrapper)
2. **sqa** - Strategy framework (refactored, v1.0.0)
3. **sqa-cli** - CLI tool with AI integration

## Current Status

✅ **Completed:**
- Comprehensive codebase review
- Architecture planning and design
- sqa-talib gem created (locally, awaiting repo authorization)

🔄 **In Progress:**
- Documenting architecture decisions
- Preparing sqa-talib for transfer to dedicated repo

⏳ **Pending:**
- sqa-cli gem creation
- sqa repo refactoring to v1.0.0
- Integration testing

---

## Architecture Overview

### Before (Monolithic)
```
sqa (one gem)
├── Indicators (Ruby implementations)
├── Strategies
├── CLI commands
├── Data loading
├── Portfolio management
└── Everything else
```

### After (Modular)
```
┌─────────────────────────────────────┐
│           sqa-cli                   │
│    (CLI Tool - Application)         │
│  - Commands                         │
│  - Data loading                     │
│  - AI integration                   │
│  - Portfolio management             │
└─────────────────────────────────────┘
              ↓              ↓
   ┌─────────────────┐   ┌─────────────────┐
   │   sqa-talib     │   │      sqa        │
   │  (Indicators)   │   │  (Strategies)   │
   │                 │   │                 │
   │  - TA-Lib wrap  │   │  - Strategy API │
   │  - 200+ indics  │   │  - Built-ins    │
   │  - NEW REPO     │   │  - Backtesting  │
   └─────────────────┘   │  - DataFrame    │
            ↓             │  - REFACTORED   │
   ┌─────────────────┐   └─────────────────┘
   │   ta_lib_ffi    │            ↓
   │  (C library)    │   ┌─────────────────┐
   └─────────────────┘   │   sqa-talib     │
                         │  (uses for data)│
                         └─────────────────┘
```

---

## Detailed Component Breakdown

### 1. sqa-talib (NEW - Indicator Library)

**Repository:** https://github.com/MadBomber/sqa-talib
**Version:** 0.1.0
**Status:** Created locally, awaiting repo access

**Purpose:** Pure technical analysis indicator library wrapping TA-Lib

**What it contains:**
- Ruby wrapper around `ta_lib_ffi` gem
- 200+ technical indicators from TA-Lib C library
- Clean Ruby API with keyword arguments
- Parameter validation and error handling
- Comprehensive test suite
- Full documentation (MkDocs)

**Key indicators implemented:**
- **Overlap Studies:** SMA, EMA, WMA, BBANDS
- **Momentum:** RSI, MACD, STOCH, MOM
- **Volatility:** ATR, TRANGE
- **Volume:** OBV, AD
- **Patterns:** Doji, Hammer, Engulfing, and 60+ more

**Dependencies:**
- `ta_lib_ffi ~> 0.3` (requires TA-Lib C library)

**API Example:**
```ruby
require 'sqa/talib'

prices = [44.34, 44.09, 44.15, 43.61, 44.33]

# Simple API
sma = SQA::TALib.sma(prices, period: 5)
rsi = SQA::TALib.rsi(prices, period: 14)
upper, middle, lower = SQA::TALib.bbands(prices, period: 20)
```

**Files created:**
```
sqa-talib/
├── lib/sqa/talib.rb            # Main wrapper (300+ lines)
├── lib/sqa/talib/version.rb
├── sqa-talib.gemspec
├── README.md
├── LICENSE (MIT)
├── CHANGELOG.md
├── Gemfile
├── Rakefile
├── test/
│   ├── test_helper.rb
│   └── sqa/talib_test.rb       # Comprehensive tests
├── docs/
│   ├── index.md
│   ├── getting-started/
│   │   ├── installation.md
│   │   └── quick-start.md
│   ├── api-reference.md
│   └── mkdocs.yml
└── .github/workflows/
    ├── test.yml                 # CI for Ruby 3.1, 3.2, 3.3
    └── docs.yml                 # Auto-deploy docs
```

---

### 2. sqa (REFACTORED - Strategy Framework)

**Repository:** https://github.com/MadBomber/sqa
**Version:** 0.0.25 → 1.0.0 (breaking change)
**Status:** Awaiting refactoring

**Purpose:** Trading strategy development and execution framework

**What stays:**
- ✅ Strategy framework (`lib/sqa/strategy/`)
- ✅ Built-in strategies (Random, RSI, SMA, EMA, MR, MP, Consensus)
- ✅ DataFrame (`lib/sqa/data_frame.rb`)
- ✅ Patches (`lib/patches/`)
- ✅ Backtesting framework (to be enhanced)

**What moves out:**
- ❌ Indicator implementations → moved to sqa-talib
- ❌ CLI commands → moved to sqa-cli
- ❌ Stock, Portfolio, Config classes → moved to sqa-cli
- ❌ Data loading code → moved to sqa-cli
- ❌ Trade/Activity tracking → moved to sqa-cli

**New dependencies:**
```ruby
spec.add_dependency 'sqa-talib', '~> 0.1'  # For indicator calculations
spec.add_dependency 'hashie', '~> 5.0'     # DataFrame (upgrade from 4.1)
```

**Migration path:**
```ruby
# Old (v0.x) - DEPRECATED
SQA::Indicator.rsi(prices, 14)

# New (v1.x) - Use sqa-talib
require 'sqa/talib'
SQA::TALib.rsi(prices, period: 14)

# Strategies stay the same
SQA::Strategy::RSI.new.analyze(data)
```

**Documentation needed:**
- MIGRATION.md - Upgrade guide for v0.x → v1.0
- Updated README explaining new architecture
- Deprecation notices for old APIs

---

### 3. sqa-cli (NEW - CLI Application)

**Repository:** https://github.com/MadBomber/sqa-cli
**Version:** 0.1.0
**Status:** To be created

**Purpose:** Complete command-line tool for stock analysis with AI

**What it contains:**
- CLI commands (analyze, backtest, report, web)
- Data loading (AlphaVantage, Yahoo Finance, CSV)
- Stock and Portfolio management
- Trade and Activity tracking
- SQLite persistence (NEW!)
- AI integration with ruby_llm (NEW!)
- Configuration management
- Web interface (to be completed)

**Dependencies:**
```ruby
# Core gems
spec.add_dependency 'sqa', '~> 1.0'         # Strategies
spec.add_dependency 'sqa-talib', '~> 0.1'   # Indicators

# CLI
spec.add_dependency 'dry-cli'
spec.add_dependency 'tty-table'

# Data sources
spec.add_dependency 'alphavantage'
spec.add_dependency 'faraday'
spec.add_dependency 'api_key_manager'

# Storage
spec.add_dependency 'sqlite3'               # NEW!

# AI Integration
spec.add_dependency 'ruby_llm'              # NEW!
spec.add_dependency 'ruby_llm-mcp'          # NEW!
spec.add_dependency 'prompt_manager'        # NEW!

# Utilities
spec.add_dependency 'nenv'
spec.add_dependency 'sem_version'
```

**Structure:**
```
sqa-cli/
├── bin/sqa                     # Main executable
├── lib/sqa/cli/
│   ├── commands/
│   │   ├── analyze.rb          # Portfolio analysis
│   │   ├── backtest.rb         # Strategy backtesting
│   │   ├── report.rb           # Report generation
│   │   └── web.rb              # Web interface
│   ├── stock.rb
│   ├── portfolio.rb
│   ├── config.rb
│   ├── storage.rb              # SQLite persistence
│   └── ai/                     # AI integration
│       ├── client.rb           # ruby_llm wrapper
│       ├── analyzer.rb         # Strategy analysis
│       ├── commentator.rb      # Market commentary
│       └── prompt_manager.rb   # Prompt templates
└── docs/
    ├── installation.md
    ├── commands/
    ├── ai-integration/
    └── tutorials/
```

---

## AI Integration Strategy

### Libraries Used

1. **ruby_llm** - Core LLM integration
   - Multi-provider support (OpenAI, Anthropic, local models)
   - Unified API

2. **ruby_llm-mcp** - Model Context Protocol
   - External data source integration
   - Real-time market data feeds
   - News and sentiment analysis

3. **prompt_manager** - Prompt template management
   - Structured prompts for analysis
   - Context-aware recommendations
   - Configurable AI personality

### AI Features Planned

**Strategy Analysis:**
```bash
sqa analyze --ticker AAPL --ai-commentary
```
- LLM analyzes historical performance
- Recommends best strategies for specific stocks
- Explains reasoning in natural language

**Natural Language Queries:**
```bash
sqa query "What's the best strategy for AAPL in the last 6 months?"
```
- Parse user questions
- Run analysis
- Generate conversational responses

**Market Commentary:**
```bash
sqa report --portfolio portfolio.csv --ai-summary
```
- Generate portfolio summaries
- Explain indicator signals
- Risk assessment with reasoning

**Backtesting Narratives:**
```bash
sqa backtest --strategy rsi --ai-explain
```
- Analyze why strategy succeeded/failed
- Identify market conditions
- Suggest improvements

---

## Key Decisions Made

### 1. TA-Lib vs Pure Ruby
**Decision:** Use TA-Lib C library (via ta_lib_ffi)

**Rationale:**
- 200+ battle-tested indicators
- 30x faster than pure Ruby
- Industry standard
- Well-documented

**Trade-off:** Requires system dependency (TA-Lib C library)

### 2. Repository Structure
**Decision:** 3 separate gems (sqa-talib, sqa, sqa-cli)

**Rationale:**
- Clear separation of concerns
- Users can pick what they need
- Each component focused and maintainable
- Library users don't need CLI dependencies

**Alternative considered:** Keep everything in sqa repo (rejected - too complex)

### 3. Namespace Strategy
**Decision:** Keep `SQA` namespace for all gems

**Rationale:**
- Simple for users
- No confusion with nested namespaces
- Clear module names distinguish purposes:
  - `SQA::TALib` - Indicators
  - `SQA::Strategy` - Strategies
  - `SQA::CLI` - CLI commands

### 4. Version Numbers
**Decision:**
- sqa-talib: 0.1.0 (new gem)
- sqa: 0.0.25 → 1.0.0 (breaking changes)
- sqa-cli: 0.1.0 (new gem)

**Rationale:**
- v1.0.0 for sqa signals major refactoring
- Semantic versioning clearly indicates breaking changes
- New gems start at 0.1.0 (experimental)

### 5. Data Storage
**Decision:** SQLite for sqa-cli

**Rationale:**
- No server setup required
- Fast queries for analysis
- Single-file database (portable)
- Easy migration to PostgreSQL later if needed
- Keep CSV for portability and user editing

### 6. Documentation
**Decision:** MkDocs with Material theme, GitHub Pages hosting

**Rationale:**
- Beautiful, professional docs
- Easy to write (Markdown)
- Search, dark mode, responsive
- Auto-deployed via GitHub Actions
- Free hosting on GitHub Pages

### 7. Ruby Version
**Decision:** Require Ruby >= 3.1.0

**Rationale:**
- ta_lib_ffi requires Ruby >= 3.1
- Modern Ruby features
- Better performance
- Still widely supported

### 8. AI Library Choice
**Decision:** ruby_llm + ruby_llm-mcp + prompt_manager

**Rationale:**
- Multi-provider support (not locked to one LLM)
- MCP for external data integration
- Structured prompt management
- Active development
- Clean API

---

## Migration Guide (v0.x → v1.0)

### For Library Users

**Old way (v0.x):**
```ruby
require 'sqa'

prices = [100, 101, 102]
rsi = SQA::Indicator.rsi(prices, 14)
```

**New way (v1.0+):**
```ruby
require 'sqa/talib'  # Add this gem
require 'sqa'

prices = [100, 101, 102]
rsi = SQA::TALib.rsi(prices, period: 14)  # Changed!

# Strategies work the same
strategy = SQA::Strategy::RSI.new
signal = strategy.analyze(data)
```

### For CLI Users

**Old way:**
```bash
gem install sqa
sqa --help  # Limited functionality
```

**New way:**
```bash
gem install sqa-cli  # Different gem!
sqa --help           # Full CLI with AI

# sqa-cli automatically installs sqa and sqa-talib
```

### Deprecation Timeline

1. **v1.0.0 Release** - Indicators removed, point to sqa-talib
2. **v1.1.0** - Add deprecation warnings for old API
3. **v2.0.0** - Remove compatibility shims

---

## Implementation Timeline

### Phase 1: Foundation (Week 1-2) ✅ IN PROGRESS
- [x] Review codebase
- [x] Design architecture
- [x] Create sqa-talib gem
- [ ] Push to GitHub (blocked by repo authorization)
- [ ] Document decisions

### Phase 2: sqa Refactoring (Week 3-4)
- [ ] Remove indicator code from sqa
- [ ] Add sqa-talib dependency
- [ ] Update tests
- [ ] Create MIGRATION.md
- [ ] Update README
- [ ] Bump to v1.0.0

### Phase 3: sqa-cli Creation (Week 5-6)
- [ ] Create sqa-cli gem structure
- [ ] Migrate CLI code from sqa
- [ ] Add SQLite persistence
- [ ] Basic AI integration
- [ ] Complete commands
- [ ] Documentation

### Phase 4: AI Integration (Week 7-8)
- [ ] ruby_llm integration
- [ ] Prompt templates
- [ ] Strategy analyzer
- [ ] Natural language interface
- [ ] MCP integration

### Phase 5: Testing & Release (Week 9-10)
- [ ] Integration testing
- [ ] Performance testing
- [ ] Documentation review
- [ ] Beta release
- [ ] Gather feedback
- [ ] Official release

---

## Testing Strategy

### Unit Tests
- Each gem has independent test suite
- Minitest framework
- SimpleCov for coverage (target: 80%+)
- CI runs on Ruby 3.1, 3.2, 3.3

### Integration Tests
- Test sqa-cli with both dependencies
- Real-world usage scenarios
- Performance benchmarks

### Manual Testing
- Install all three gems together
- Run CLI commands
- Test AI integration
- Documentation accuracy

---

## Release Checklist

### sqa-talib
- [ ] All tests passing
- [ ] Documentation complete
- [ ] README accurate
- [ ] CHANGELOG updated
- [ ] Tagged release (v0.1.0)
- [ ] Push to RubyGems.org
- [ ] GitHub Pages docs deployed

### sqa
- [ ] Indicators removed
- [ ] sqa-talib integrated
- [ ] Tests updated and passing
- [ ] MIGRATION.md written
- [ ] README updated
- [ ] CHANGELOG updated (v1.0.0)
- [ ] Tagged release
- [ ] Push to RubyGems.org
- [ ] Announce breaking changes

### sqa-cli
- [ ] All features complete
- [ ] Tests passing
- [ ] Documentation complete
- [ ] AI integration working
- [ ] CHANGELOG updated
- [ ] Tagged release (v0.1.0)
- [ ] Push to RubyGems.org
- [ ] Demo video/tutorial

---

## Open Questions

1. **API Keys Configuration**
   - How should users configure LLM API keys?
   - Environment variables? Config file? Both?

2. **Web Interface**
   - Rails or Sinatra?
   - Should it be separate from CLI?

3. **Backtesting Engine**
   - Should backtesting be in sqa (strategies) or sqa-cli (application)?
   - Current plan: Core in sqa, CLI interface in sqa-cli

4. **Deployment**
   - Will users deploy sqa-cli as a service?
   - Container support needed?

---

## Risk Mitigation

### Risk: TA-Lib Installation Complexity
**Mitigation:**
- Comprehensive installation docs
- Docker image with TA-Lib pre-installed
- Error messages with installation instructions

### Risk: Breaking Changes in v1.0
**Mitigation:**
- Clear migration guide
- Deprecation warnings
- Blog post announcing changes
- Email to known users

### Risk: AI Integration Costs
**Mitigation:**
- Support multiple LLM providers (including free/local)
- Rate limiting
- Caching responses
- Optional feature (not required)

### Risk: Three Gems Coordination
**Mitigation:**
- Careful semantic versioning
- Integration tests
- Coordinated releases
- Clear dependency specifications

---

## Success Metrics

### Technical
- [ ] All tests passing
- [ ] 80%+ code coverage
- [ ] Documentation coverage: 100%
- [ ] Zero critical bugs

### User Adoption
- [ ] 100+ gem downloads in first month
- [ ] 5+ GitHub stars per repo
- [ ] Positive feedback on Reddit/HN

### Performance
- [ ] Indicator calculations <1ms (TA-Lib)
- [ ] CLI commands respond <5s
- [ ] AI queries <10s

---

## Resources

### Documentation
- [TA-Lib](https://ta-lib.org/) - C library documentation
- [ta_lib_ffi](https://github.com/TA-Lib/ta-lib-ruby) - Ruby FFI wrapper
- [ruby_llm](https://github.com/patterns-ai-core/ruby_llm) - LLM integration
- [MkDocs Material](https://squidfunk.github.io/mkdocs-material/) - Documentation theme

### Similar Projects
- [TA-Lib](https://github.com/mrjbq7/ta-lib) - Python wrapper
- [Backtrader](https://www.backtrader.com/) - Python backtesting framework
- [ruby-technical-analysis](https://github.com/intrinio/technical-analysis) - Pure Ruby indicators

---

## Contact & Support

- **Author:** Dewayne VanHoozer
- **Email:** dvanhoozer@gmail.com
- **GitHub:** https://github.com/MadBomber
- **Issues:** Use GitHub issues for each repository

---

**Last Updated:** 2025-01-05
**Next Review:** After sqa-talib repository access granted
