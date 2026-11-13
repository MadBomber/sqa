# Backtesting Framework

## Overview

Simulate trading strategies on historical data to evaluate performance before risking real capital.

## Quick Start

```ruby
require 'sqa'

# Load stock data
stock = SQA::Stock.new(ticker: 'AAPL')

# Create backtest
backtest = SQA::Backtest.new(
  stock: stock,
  strategy: SQA::Strategy::RSI,
  initial_capital: 10_000,
  commission: 1.0
)

# Run simulation
results = backtest.run

# View results
puts "Total Return: #{(results.total_return * 100).round(2)}%"
puts "Sharpe Ratio: #{results.sharpe_ratio}"
puts "Max Drawdown: #{(results.max_drawdown * 100).round(2)}%"
puts "Win Rate: #{(results.win_rate * 100).round(2)}%"
```

## Configuration

### Basic Parameters

```ruby
backtest = SQA::Backtest.new(
  stock: stock,                    # SQA::Stock object
  strategy: SQA::Strategy::MACD,   # Strategy class
  initial_capital: 10_000,         # Starting capital
  commission: 1.0,                 # Per-trade commission
  position_size: :all_cash,        # :all_cash, or a fraction of cash per trade (e.g. 0.5)
  start_date: '2020-01-01',        # Optional; defaults to the first row
  end_date: '2023-12-31'           # Optional; defaults to the last row
)
```

## Results Object

The `backtest.run` method returns a `SQA::Backtest::Results` object with:

### Return Metrics
- `total_return` - Total return as a fraction (0.155 = 15.5%)
- `annualized_return` - Return per year

### Risk Metrics
- `sharpe_ratio` - Risk-adjusted return
- `max_drawdown` - Largest peak-to-trough decline

### Trading Metrics
- `total_trades` - Total number of trades
- `winning_trades` / `losing_trades` - Counts of profitable and unprofitable trades
- `win_rate` - Fraction of profitable trades (0.6 = 60%)
- `average_win` - Average winning trade
- `average_loss` - Average losing trade
- `profit_factor` - Gross profit / gross loss

### Portfolio Metrics
- `initial_capital` / `final_value` - Starting and ending portfolio value
- `start_date` / `end_date` - Backtest period

The value over time and the trade history live on the backtest itself:
`backtest.equity_curve` (an array of `{ date:, value:, price: }` hashes) and
`backtest.portfolio.trades`.

## Complete Example

```ruby
# Load data
stock = SQA::Stock.new(ticker: 'AAPL')

# Test multiple strategies
strategies = [
  SQA::Strategy::RSI,
  SQA::Strategy::MACD,
  SQA::Strategy::BollingerBands
]

strategies.each do |strategy|
  backtest = SQA::Backtest.new(
    stock: stock,
    strategy: strategy,
    initial_capital: 10_000
  )
  
  results = backtest.run
  
  puts "\n#{strategy.name} Results:"
  puts "-" * 40
  puts "Return: #{(results.total_return * 100).round(2)}%"
  puts "Sharpe: #{results.sharpe_ratio.round(2)}"
  puts "Max DD: #{(results.max_drawdown * 100).round(2)}%"
  puts "Trades: #{results.total_trades}"
  puts "Win Rate: #{(results.win_rate * 100).round(2)}%"
end
```

## Advanced Usage

### Custom Date Range

```ruby
# Backtest specific period
stock = SQA::Stock.new(ticker: 'AAPL')

backtest = SQA::Backtest.new(
  stock: stock,
  strategy: strategy,
  start_date: '2020-01-01',
  end_date: '2023-12-31'
)
results = backtest.run
```

### Parameter Optimization

```ruby
# Test different RSI thresholds
(20..40).step(5).each do |oversold|
  results = test_strategy_with_params(oversold)
  puts "RSI #{oversold}: Return = #{(results.total_return * 100).round(2)}%"
end
```

### Walk-Forward Testing

```ruby
# Train on first 70%, test on last 30%
train_end = (stock.df.height * 0.7).to_i
train_stock = stock.df[0...train_end]
test_stock = stock.df[train_end..-1]

# Optimize on training data
best_params = optimize_on(train_stock)

# Validate on test data
results = backtest_with_params(test_stock, best_params)
```

## Visualization

```ruby
# Plot equity curve
require 'gruff'

g = Gruff::Line.new
g.title = "Portfolio Value Over Time"
g.data("Portfolio", backtest.equity_curve.map { |point| point[:value] })
g.write('equity_curve.png')
```

## Best Practices

### 1. Use Enough Data
- Minimum: 252 trading days (1 year)
- Recommended: 1260+ days (5 years)
- Include different market conditions

### 2. Account for Costs
```ruby
backtest = SQA::Backtest.new(
  stock: stock,
  strategy: strategy,
  commission: 1.0         # Per trade
)
```

Slippage is not modeled; fold an estimate into `commission` if needed.

### 3. Avoid Overfitting
- Use walk-forward analysis
- Test on out-of-sample data
- Limit parameter optimization

### 4. Compare to Benchmark
```ruby
prices = stock.df["adj_close_price"].to_a
buy_and_hold_return = (prices.last - prices.first) / prices.first

if results.total_return < buy_and_hold_return
  puts "⚠️  Strategy underperforms buy-and-hold"
end
```

### 5. Check Multiple Metrics
Don't rely on return alone:
- Sharpe ratio (risk-adjusted)
- Max drawdown (worst case)
- Win rate (consistency)
- Profit factor (quality)

## Common Pitfalls

❌ **Survivorship Bias**: Only testing stocks that still exist  
❌ **Look-Ahead Bias**: Using future data  
❌ **Curve Fitting**: Over-optimizing parameters  
❌ **Ignoring Costs**: Unrealistic commission/slippage  
❌ **Small Sample**: Too few trades for statistical significance  

## Related

- [Portfolio Management](portfolio.md) - Track positions and P&L
- [Strategy Generator](strategy-generator.md) - Discover patterns
- [Risk Management](risk-management.md) - Position sizing and risk metrics

