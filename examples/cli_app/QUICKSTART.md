# SQA CLI Quick Reference

## Installation

```bash
cd examples/cli_app
./sqa-cli help
```

## Quick Commands

### 1. Backtest a Strategy
```bash
./sqa-cli backtest --ticker AAPL --strategy RSI
./sqa-cli backtest --ticker AAPL --compare      # Compare all strategies
```

### 2. Evolve Parameters
```bash
./sqa-cli genetic --ticker AAPL --generations 30
```

### 3. Discover Patterns
```bash
./sqa-cli pattern --ticker AAPL --min-gain 10 --generate
```

### 4. Analyze Stock
```bash
./sqa-cli analyze --ticker AAPL                 # All analyses
./sqa-cli analyze --ticker AAPL --methods fpop  # Just FPOP
```

### 5. Knowledge-Based Strategy
```bash
./sqa-cli kbs --ticker AAPL --backtest
```

### 6. Streaming Simulation
```bash
./sqa-cli stream --ticker AAPL --strategies RSI,MACD
```

### 7. Portfolio Optimization
```bash
./sqa-cli optimize --tickers AAPL,MSFT,GOOGL
```

## Common Options

- `-t, --ticker SYMBOL` - Stock ticker (default: AAPL)
- `-v, --verbose` - Show detailed output
- `-h, --help` - Show help for command

## Complete Workflow

```bash
# 1. Analyze
./sqa-cli analyze --ticker AAPL

# 2. Find patterns
./sqa-cli pattern --ticker AAPL --min-gain 10

# 3. Optimize parameters
./sqa-cli genetic --ticker AAPL

# 4. Backtest
./sqa-cli backtest --ticker AAPL --compare

# 5. Build portfolio
./sqa-cli optimize --tickers AAPL,MSFT,GOOGL
```

## Getting Help

```bash
./sqa-cli help                    # General help
./sqa-cli backtest --help         # Command-specific help
./sqa-cli pattern --help          # Command-specific help
```

See README.md for detailed documentation.
