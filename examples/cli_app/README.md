# SQA CLI - Command Line Interface

A unified command-line interface for all SQA (Simple Qualitative Analysis) features. This CLI consolidates the functionality from all example scripts into a single, easy-to-use tool with subcommands.

## Installation

The CLI is located in `examples/cli_app/` and can be run directly:

```bash
cd examples/cli_app
./sqa-cli help
```

Or create a symlink for easier access:

```bash
ln -s $(pwd)/examples/cli_app/sqa-cli /usr/local/bin/sqa-cli
```

## Usage

```bash
sqa-cli <command> [options]
```

### Available Commands

#### 1. `backtest` - Strategy Backtesting

Run strategy backtests on historical data.

```bash
# Backtest RSI strategy
sqa-cli backtest --ticker AAPL --strategy RSI

# Compare all strategies
sqa-cli backtest --ticker AAPL --compare

# Custom capital and commission
sqa-cli backtest --ticker MSFT --strategy MACD --capital 50000 --commission 0.5
```

**Options:**
- `-t, --ticker SYMBOL` - Stock ticker (default: AAPL)
- `-s, --strategy NAME` - Strategy to test (RSI, SMA, EMA, MACD, BollingerBands, Stochastic, VolumeBreakout, KBS, Consensus)
- `-c, --capital AMOUNT` - Initial capital (default: 10000)
- `--commission AMOUNT` - Commission per trade (default: 1.0)
- `--compare` - Compare all strategies

**Output:**
- Total return, annualized return
- Sharpe ratio
- Maximum drawdown
- Win rate, total trades
- Profit factor

---

#### 2. `genetic` - Genetic Programming

Evolve optimal strategy parameters using genetic algorithms.

```bash
# Basic genetic programming
sqa-cli genetic --ticker AAPL

# Larger population and more generations
sqa-cli genetic --ticker GOOGL --population 50 --generations 30

# Custom mutation and crossover rates
sqa-cli genetic --ticker TSLA --mutation-rate 0.2 --crossover-rate 0.8
```

**Options:**
- `-t, --ticker SYMBOL` - Stock ticker
- `-p, --population SIZE` - Population size (default: 20)
- `-g, --generations COUNT` - Number of generations (default: 10)
- `-m, --mutation-rate RATE` - Mutation rate (default: 0.15)
- `-c, --crossover-rate RATE` - Crossover rate (default: 0.7)

**Output:**
- Best parameters found (RSI period, buy/sell thresholds)
- Fitness score (total return)
- Evolution history
- Backtest results for best individual

---

#### 3. `pattern` - Pattern Discovery

Discover profitable trading patterns by reverse-engineering historical trades.

```bash
# Discover patterns with 10% minimum gain
sqa-cli pattern --ticker AAPL --min-gain 10

# More aggressive pattern mining
sqa-cli pattern --ticker NVDA --min-gain 20 --fpop 5

# Generate and backtest strategies from patterns
sqa-cli pattern --ticker AMD --min-gain 15 --generate

# Export patterns to CSV
sqa-cli pattern --ticker MSFT --export patterns.csv
```

**Options:**
- `-t, --ticker SYMBOL` - Stock ticker
- `-g, --min-gain PERCENT` - Minimum gain percent (default: 10.0)
- `-f, --fpop DAYS` - Future period of performance (default: 10)
- `-m, --min-frequency COUNT` - Minimum pattern frequency (default: 3)
- `-w, --window DAYS` - Inflection detection window (default: 3)
- `-n, --max-patterns COUNT` - Max patterns to display (default: 10)
- `-e, --export FILE` - Export patterns to CSV
- `--generate` - Generate and backtest strategies

**Output:**
- Discovered patterns with conditions
- Pattern frequency and average gain
- Success rate and holding period
- Generated strategy backtest results

---

#### 4. `analyze` - Stock Analysis

Run various analysis methods on stocks.

```bash
# Run all analyses
sqa-cli analyze --ticker AAPL

# Specific analyses
sqa-cli analyze --ticker MSFT --methods fpop,regime
sqa-cli analyze --ticker GOOGL --methods seasonal

# Custom FPOP periods
sqa-cli analyze --ticker TSLA --methods fpop --fpop-periods 20
```

**Options:**
- `-t, --ticker SYMBOL` - Stock ticker
- `-m, --methods METHODS` - Analysis methods (comma-separated): fpop, regime, seasonal, all (default: all)
- `--fpop-periods DAYS` - FPOP analysis periods (default: 10)
- `--regime-window DAYS` - Regime detection window (default: 60)

**Analysis Types:**

**FPOP (Future Period Loss/Profit):**
- Shows potential future price movements
- Identifies high-quality opportunities
- Risk and magnitude metrics

**Market Regime:**
- Detects bull/bear/sideways markets
- Volatility classification
- Regime strength and trend
- Historical regime changes

**Seasonal:**
- Best/worst months and quarters
- Monthly average returns
- Quarterly performance
- Seasonal pattern detection

---

#### 5. `kbs` - Knowledge-Based Strategy

Run knowledge-based strategy using RETE forward-chaining inference.

```bash
# Use default rules
sqa-cli kbs --ticker AAPL

# Use custom rules
sqa-cli kbs --ticker MSFT --rules custom

# Show rules and facts
sqa-cli kbs --ticker GOOGL --show-rules --show-facts

# Run backtest
sqa-cli kbs --ticker AMD --backtest
```

**Options:**
- `-t, --ticker SYMBOL` - Stock ticker
- `-r, --rules TYPE` - Rule set (default, custom, minimal)
- `--show-rules` - Display loaded rules
- `--show-facts` - Display asserted facts
- `-b, --backtest` - Run backtest with strategy

**Rule Sets:**
- **default:** 10 built-in trading rules
- **custom:** Aggressive multi-condition rules
- **minimal:** Simple RSI and MACD rules

**Output:**
- Trading signal (BUY/SELL/HOLD)
- Signal reasoning
- Working memory facts
- Backtest results (if requested)

---

#### 6. `stream` - Real-Time Streaming

Simulate real-time price streaming with strategy execution.

```bash
# Stream with RSI strategy
sqa-cli stream --ticker AAPL

# Multiple strategies
sqa-cli stream --ticker MSFT --strategies RSI,MACD,KBS

# Custom window and updates
sqa-cli stream --ticker GOOGL --window 200 --updates 100
```

**Options:**
- `-t, --ticker SYMBOL` - Stock ticker
- `-s, --strategies LIST` - Strategies to run (comma-separated, default: RSI)
- `-w, --window SIZE` - Rolling window size (default: 100)
- `-u, --updates COUNT` - Number of price updates (default: 50)

**Output:**
- Real-time signals as they're generated
- Signal breakdown (buy/sell/hold counts)
- Last 5 signals with prices

---

#### 7. `optimize` - Portfolio Optimization

Optimize portfolio allocation across multiple stocks.

```bash
# Maximum Sharpe ratio
sqa-cli optimize --tickers AAPL,MSFT,GOOGL

# Minimum variance
sqa-cli optimize --tickers AAPL,MSFT,GOOGL,AMZN --method variance

# Risk parity
sqa-cli optimize --tickers SPY,TLT,GLD --method risk_parity

# Efficient frontier
sqa-cli optimize --tickers AAPL,MSFT,GOOGL --method efficient_frontier

# Show risk metrics
sqa-cli optimize --tickers AAPL,MSFT --risk-metrics
```

**Options:**
- `--tickers LIST` - Comma-separated ticker list (default: AAPL,MSFT,GOOGL)
- `-m, --method METHOD` - Optimization method (sharpe, variance, risk_parity, efficient_frontier)
- `--risk-free-rate RATE` - Risk-free rate (default: 0.02)
- `--risk-metrics` - Show individual stock risk metrics

**Output:**
- Optimal portfolio weights
- Expected return and volatility
- Sharpe ratio
- Individual stock metrics (if requested)

---

## Common Options

All commands support these options:

- `-t, --ticker SYMBOL` - Stock ticker symbol (default: AAPL)
- `-v, --verbose` - Verbose output with additional details
- `-h, --help` - Show command-specific help

## Examples

### Complete Workflow Example

```bash
# 1. Analyze the stock
sqa-cli analyze --ticker AAPL --methods all

# 2. Discover profitable patterns
sqa-cli pattern --ticker AAPL --min-gain 10 --generate

# 3. Optimize strategy parameters
sqa-cli genetic --ticker AAPL --generations 30

# 4. Backtest optimized strategy
sqa-cli backtest --ticker AAPL --strategy RSI

# 5. Compare against other strategies
sqa-cli backtest --ticker AAPL --compare

# 6. Build portfolio across multiple stocks
sqa-cli optimize --tickers AAPL,MSFT,GOOGL,AMZN
```

### Multi-Stock Analysis

```bash
# Analyze multiple stocks
for ticker in AAPL MSFT GOOGL AMZN; do
  echo "\n=== $ticker ==="
  sqa-cli analyze --ticker $ticker --methods regime,seasonal
done
```

### Pattern Mining Campaign

```bash
# Mine patterns at different gain thresholds
for gain in 5 10 15 20; do
  echo "\n=== ${gain}% Gain Patterns ==="
  sqa-cli pattern --ticker AAPL --min-gain $gain --max-patterns 5
done
```

## Architecture

```
examples/cli_app/
├── sqa-cli                    # Main executable
├── lib/
│   ├── cli.rb                 # CLI dispatcher
│   ├── commands/
│   │   ├── base.rb            # Base command class
│   │   ├── backtest.rb        # Backtesting command
│   │   ├── genetic.rb         # Genetic programming
│   │   ├── pattern.rb         # Pattern discovery
│   │   ├── analyze.rb         # Analysis methods
│   │   ├── kbs.rb             # Knowledge-based strategy
│   │   ├── stream.rb          # Real-time streaming
│   │   └── optimize.rb        # Portfolio optimization
│   └── helpers/               # Helper utilities (future)
└── README.md                  # This file
```

## Requirements

- Ruby >= 3.2
- SQA gem with all dependencies
- TA-Lib library (for technical indicators)
- Redis (for KBS blackboard persistence)

## Environment Setup

```bash
# Set Alpha Vantage API key (optional, for live data)
export AV_API_KEY="your_api_key_here"

# Or use Yahoo Finance (no API key needed)
# Data source is automatically selected
```

## Troubleshooting

**Command not found:**
```bash
# Make sure the executable has proper permissions
chmod +x examples/cli_app/sqa-cli

# Or run with ruby explicitly
ruby examples/cli_app/sqa-cli help
```

**TA-Lib errors:**
```bash
# Install TA-Lib library
brew install ta-lib           # macOS
sudo apt-get install ta-lib   # Ubuntu/Debian
```

**Redis connection errors:**
```bash
# Start Redis server (required for KBS)
redis-server
```

## Comparison with Example Scripts

The CLI consolidates functionality from these example scripts:

| Example Script                    | CLI Command          |
|-----------------------------------|----------------------|
| `strategy_generator_example.rb`   | `sqa-cli pattern`    |
| `genetic_programming_example.rb`  | `sqa-cli genetic`    |
| `kbs_strategy_example.rb`         | `sqa-cli kbs`        |
| `realtime_stream_example.rb`      | `sqa-cli stream`     |
| `fpop_analysis_example.rb`        | `sqa-cli analyze`    |
| `pattern_context_example.rb`      | `sqa-cli analyze`    |
| `advanced_features_example.rb`    | Multiple commands    |

## Documentation

For more information about SQA features:
- Main README: `../../README.md`
- CLAUDE.md: `../../CLAUDE.md`
- Documentation: https://github.com/MadBomber/sqa

## License

MIT License - Same as SQA library
