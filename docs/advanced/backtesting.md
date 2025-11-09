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
  initial_cash: 10_000,
  commission: 1.0
)

# Run simulation
results = backtest.run

# View results
puts "Total Return: #{results.total_return}%"
puts "Sharpe Ratio: #{results.sharpe_ratio}"
puts "Max Drawdown: #{results.max_drawdown}%"
puts "Win Rate: #{results.win_rate}%"
```

## Configuration

### Basic Parameters

```ruby
backtest = SQA::Backtest.new(
  stock: stock,                    # SQA::Stock object
  strategy: SQA::Strategy::MACD,   # Strategy class
  initial_cash: 10_000,            # Starting capital
  commission: 1.0,                 # Per-trade commission
  position_size: 100               # Shares per trade
)
```

## Results Object

The `backtest.run` method returns a results object with:

### Return Metrics
- `total_return` - Total percentage return
- `annualized_return` - Return per year
- `benchmark_return` - Buy-and-hold comparison

### Risk Metrics
- `sharpe_ratio` - Risk-adjusted return
- `sortino_ratio` - Downside risk-adjusted return
- `max_drawdown` - Largest peak-to-trough decline
- `volatility` - Standard deviation of returns

### Trading Metrics
- `num_trades` - Total number of trades
- `win_rate` - Percentage of profitable trades
- `avg_win` - Average winning trade
- `avg_loss` - Average losing trade
- `profit_factor` - Gross profit / gross loss

### Portfolio Metrics
- `final_value` - Ending portfolio value
- `portfolio_value` - Value over time (array)
- `trades` - Full trade history

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
    initial_cash: 10_000
  )
  
  results = backtest.run
  
  puts "\n#{strategy.name} Results:"
  puts "-" * 40
  puts "Return: #{results.total_return.round(2)}%"
  puts "Sharpe: #{results.sharpe_ratio.round(2)}"
  puts "Max DD: #{results.max_drawdown.round(2)}%"
  puts "Trades: #{results.num_trades}"
  puts "Win Rate: #{results.win_rate.round(2)}%"
end
```

## Advanced Usage

### Custom Date Range

```ruby
# Backtest specific period
stock = SQA::Stock.new(
  ticker: 'AAPL',
  start_date: '2020-01-01',
  end_date: '2023-12-31'
)

backtest = SQA::Backtest.new(stock: stock, strategy: strategy)
results = backtest.run
```

### Parameter Optimization

```ruby
# Test different RSI thresholds
(20..40).step(5).each do |oversold|
  results = test_strategy_with_params(oversold)
  puts "RSI #{oversold}: Return = #{results.total_return}%"
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
g.data("Portfolio", results.portfolio_value)
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
  commission: 1.0,        # Per trade
  slippage: 0.001         # 0.1% slippage
)
```

### 3. Avoid Overfitting
- Use walk-forward analysis
- Test on out-of-sample data
- Limit parameter optimization

### 4. Compare to Benchmark
```ruby
if results.total_return < results.benchmark_return
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

