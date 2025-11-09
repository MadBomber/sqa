# Portfolio Management

## Overview

The Portfolio class tracks positions, calculates P&L, manages commissions, and monitors portfolio performance over time.

## Creating a Portfolio

```ruby
require 'sqa'

portfolio = SQA::Portfolio.new(
  initial_cash: 10_000,    # Starting capital
  commission: 1.0           # Commission per trade
)
```

## Basic Operations

### Buy Stock

```ruby
portfolio.buy('AAPL', shares: 10, price: 150.0)
# Deducts: (10 × $150) + $1 commission = $1,501

puts portfolio.cash  # => 8,499.0
puts portfolio.positions['AAPL']  # => 10 shares
```

### Sell Stock

```ruby
portfolio.sell('AAPL', shares: 5, price: 160.0)
# Adds: (5 × $160) - $1 commission = $799

puts portfolio.cash  # => 9,298.0
puts portfolio.positions['AAPL']  # => 5 shares
```

### Calculate Portfolio Value

```ruby
current_prices = {
  'AAPL' => 165.0,
  'GOOGL' => 2800.0
}

total_value = portfolio.value(current_prices)
# Cash + (positions × current prices)
```

## Complete Example

```ruby
# Initialize
portfolio = SQA::Portfolio.new(initial_cash: 10_000)

# Buy multiple stocks
portfolio.buy('AAPL', shares: 10, price: 150.0)
portfolio.buy('GOOGL', shares: 2, price: 2750.0)

# Check positions
puts "Positions: #{portfolio.positions}"
# => {"AAPL"=>10, "GOOGL"=>2}

# Calculate current value
prices = { 'AAPL' => 160.0, 'GOOGL' => 2800.0 }
puts "Portfolio Value: $#{portfolio.value(prices)}"

# Sell some shares
portfolio.sell('AAPL', shares: 5, price: 160.0)

# View trade history
portfolio.trades.each do |trade|
  puts "#{trade.action} #{trade.shares} #{trade.ticker} @ $#{trade.price}"
end
```

## P&L Tracking

### Realized P&L
Profit/loss from closed positions (sold shares).

```ruby
# Buy 10 shares @ $150
portfolio.buy('AAPL', shares: 10, price: 150.0)

# Sell 5 shares @ $160
portfolio.sell('AAPL', shares: 5, price: 160.0)

# Realized P&L: (160 - 150) × 5 = $50
# (minus 2 × $1 commission = $48)
```

### Unrealized P&L
Paper profit/loss on open positions.

```ruby
# Still holding 5 shares bought @ $150
# Current price: $165

unrealized_pnl = (165.0 - 150.0) * 5  # => $75
```

## Portfolio Methods

| Method | Description |
|--------|-------------|
| `buy(ticker, shares:, price:)` | Purchase shares |
| `sell(ticker, shares:, price:)` | Sell shares |
| `value(current_prices)` | Calculate total portfolio value |
| `positions` | Hash of ticker → share count |
| `trades` | Array of all trades |
| `cash` | Available cash balance |

## Usage with Backtesting

```ruby
backtest = SQA::Backtest.new(
  stock: stock,
  strategy: SQA::Strategy::RSI,
  initial_cash: 10_000,
  commission: 1.0
)

results = backtest.run

puts "Final Value: $#{results.portfolio_value}"
puts "Total Return: #{results.total_return}%"
puts "Total Trades: #{results.num_trades}"
```

## Advanced Features

### Position Sizing

```ruby
# Risk-based position sizing
risk_per_trade = portfolio.cash * 0.02  # 2% risk
shares = (risk_per_trade / stop_loss_distance).to_i

portfolio.buy('AAPL', shares: shares, price: current_price)
```

### Diversification Check

```ruby
def check_diversification(portfolio, prices)
  total_value = portfolio.value(prices)
  
  portfolio.positions.each do |ticker, shares|
    position_value = shares * prices[ticker]
    percentage = (position_value / total_value) * 100
    
    puts "#{ticker}: #{percentage.round(2)}%"
    warn "⚠️  #{ticker} exceeds 20%" if percentage > 20
  end
end
```

## Related

- [Backtesting](backtesting.md) - Test strategies with portfolio tracking
- [Risk Management](risk-management.md) - Position sizing and risk metrics
- [Portfolio Optimizer](portfolio-optimizer.md) - Optimal asset allocation

