# Portfolio Optimizer

Multi-objective portfolio optimization for optimal asset allocation and rebalancing.

## Maximum Sharpe Portfolio

```ruby
# Get returns for multiple stocks
returns_matrix = ['AAPL', 'GOOGL', 'MSFT'].map do |ticker|
  stock = SQA::Stock.new(ticker: ticker)
  prices = stock.df["adj_close_price"].to_a
  prices.each_cons(2).map { |a, b| (b - a) / a }
end

# Find optimal weights
result = SQA::PortfolioOptimizer.maximum_sharpe(returns_matrix)

puts "Optimal Weights:"
puts "  AAPL: #{(result[:weights][0] * 100).round(2)}%"
puts "  GOOGL: #{(result[:weights][1] * 100).round(2)}%"
puts "  MSFT: #{(result[:weights][2] * 100).round(2)}%"
puts "\nExpected Sharpe: #{result[:sharpe].round(2)}"
```

## Minimum Variance Portfolio

```ruby
result = SQA::PortfolioOptimizer.minimum_variance(returns_matrix)
# Lowest risk allocation
```

## Risk Parity

```ruby
result = SQA::PortfolioOptimizer.risk_parity(returns_matrix)
# Equal risk contribution from each asset
```

## Efficient Frontier

```ruby
frontier = SQA::PortfolioOptimizer.efficient_frontier(
  returns_matrix,
  num_portfolios: 50
)

frontier.each do |portfolio|
  puts "Return: #{portfolio[:return]}, Risk: #{portfolio[:volatility]}"
end
```

## Multi-Objective Optimization

```ruby
result = SQA::PortfolioOptimizer.multi_objective(
  returns_matrix,
  objectives: {
    maximize_return: 0.4,
    minimize_volatility: 0.3,
    minimize_drawdown: 0.3
  }
)
```

## Rebalancing

```ruby
current_weights = [0.5, 0.3, 0.2]
target_weights = [0.4, 0.4, 0.2]

trades = SQA::PortfolioOptimizer.rebalance(
  current_weights: current_weights,
  target_weights: target_weights,
  portfolio_value: 10_000
)

# trades => [{ ticker: 'AAPL', shares: -5, value: -750 }, ...]
```

