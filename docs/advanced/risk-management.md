# Risk Management

## Overview

Comprehensive risk management tools including VaR, position sizing, and risk metrics.

## Value at Risk (VaR)

Calculate potential losses at specified confidence level:

```ruby
require 'sqa'

prices = stock.df["adj_close_price"].to_a
returns = prices.each_cons(2).map { |a, b| (b - a) / a }

# 95% confidence VaR
var_95 = SQA::RiskManager.var(returns, confidence: 0.95, method: :historical)
puts "VaR (95%): #{(var_95 * 100).round(2)}%"

# Conditional VaR (Expected Shortfall)
cvar_95 = SQA::RiskManager.cvar(returns, confidence: 0.95)
puts "CVaR (95%): #{(cvar_95 * 100).round(2)}%"
```

## Position Sizing

### Kelly Criterion

```ruby
# Optimal position size based on win rate and payoffs
position = SQA::RiskManager.kelly_criterion(
  win_rate: 0.60,        # 60% win rate
  avg_win: 0.10,         # Average 10% gain
  avg_loss: 0.05,        # Average 5% loss
  capital: 10_000
)

puts "Kelly Position: $#{position}"
```

### Fixed Fractional

```ruby
# Risk fixed % of capital per trade
position = SQA::RiskManager.fixed_fractional(
  capital: 10_000,
  risk_percent: 0.02,    # Risk 2% per trade
  stop_loss_percent: 0.05 # 5% stop loss
)

shares = (position / current_price).to_i
```

### Percent Volatility

```ruby
# Size based on volatility
position = SQA::RiskManager.percent_volatility(
  capital: 10_000,
  target_volatility: 0.02,  # 2% target vol
  price_volatility: 0.25     # Stock's 25% annualized vol
)
```

## Risk Metrics

### Sharpe Ratio

```ruby
sharpe = SQA::RiskManager.sharpe_ratio(returns, risk_free_rate: 0.02)
puts "Sharpe Ratio: #{sharpe.round(2)}"

# > 1.0 = Good
# > 2.0 = Very Good
# > 3.0 = Excellent
```

### Sortino Ratio

```ruby
# Like Sharpe but only penalizes downside volatility
sortino = SQA::RiskManager.sortino_ratio(returns, risk_free_rate: 0.02)
puts "Sortino Ratio: #{sortino.round(2)}"
```

### Calmar Ratio

```ruby
# Annual return / Maximum drawdown
prices = stock.df["adj_close_price"].to_a
calmar = SQA::RiskManager.calmar_ratio(prices)
puts "Calmar Ratio: #{calmar.round(2)}"
```

### Maximum Drawdown

```ruby
max_dd = SQA::RiskManager.max_drawdown(prices)
puts "Max Drawdown: #{(max_dd * 100).round(2)}%"
```

## Monte Carlo Simulation

```ruby
# Simulate potential outcomes
simulations = SQA::RiskManager.monte_carlo_simulation(
  returns: returns,
  initial_value: 10_000,
  periods: 252,          # 1 year
  num_simulations: 1000
)

# Analyze results
outcomes = simulations.map(&:last).sort
percentile_5 = outcomes[(outcomes.size * 0.05).to_i]
percentile_95 = outcomes[(outcomes.size * 0.95).to_i]

puts "5th percentile: $#{percentile_5.round(2)}"
puts "95th percentile: $#{percentile_95.round(2)}"
```

## Complete Example

```ruby
# Comprehensive risk assessment
class RiskAssessment
  def initialize(stock)
    @stock = stock
    @prices = stock.df["adj_close_price"].to_a
    @returns = calculate_returns
  end
  
  def assess
    {
      var_95: SQA::RiskManager.var(@returns, confidence: 0.95),
      cvar_95: SQA::RiskManager.cvar(@returns, confidence: 0.95),
      sharpe: SQA::RiskManager.sharpe_ratio(@returns),
      sortino: SQA::RiskManager.sortino_ratio(@returns),
      max_dd: SQA::RiskManager.max_drawdown(@prices),
      volatility: @returns.standard_deviation
    }
  end
  
  def position_size(capital, method: :kelly)
    case method
    when :kelly
      SQA::RiskManager.kelly_criterion(
        win_rate: calculate_win_rate,
        avg_win: calculate_avg_win,
        avg_loss: calculate_avg_loss,
        capital: capital
      )
    when :fixed
      SQA::RiskManager.fixed_fractional(
        capital: capital,
        risk_percent: 0.02,
        stop_loss_percent: 0.05
      )
    end
  end
  
  private
  
  def calculate_returns
    @prices.each_cons(2).map { |a, b| (b - a) / a }
  end
  
  def calculate_win_rate
    wins = @returns.count { |r| r > 0 }
    wins.to_f / @returns.size
  end
  
  def calculate_avg_win
    wins = @returns.select { |r| r > 0 }
    wins.sum / wins.size
  end
  
  def calculate_avg_loss
    losses = @returns.select { |r| r < 0 }
    losses.sum.abs / losses.size
  end
end

# Usage
assessment = RiskAssessment.new(stock)
metrics = assessment.assess
position = assessment.position_size(10_000, method: :kelly)

puts "Risk Metrics:"
puts "  VaR (95%): #{(metrics[:var_95] * 100).round(2)}%"
puts "  Sharpe: #{metrics[:sharpe].round(2)}"
puts "  Max DD: #{(metrics[:max_dd] * 100).round(2)}%"
puts "\nRecommended Position: $#{position.round(2)}"
```

## Best Practices

1. **Diversify**: Don't risk more than 2-5% per trade
2. **Use Stop Losses**: Always define maximum acceptable loss
3. **Monitor Correlations**: Avoid correlated positions
4. **Regular Reassessment**: Update risk metrics monthly
5. **Stress Testing**: Run Monte Carlo simulations

## Related

- [Portfolio Optimizer](portfolio-optimizer.md) - Optimal allocation
- [FPOP](fpop.md) - Risk/reward analysis
- [Backtesting](backtesting.md) - Test risk management rules

