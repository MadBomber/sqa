# 📦 SQA::RiskManager

!!! note "Description"
    RiskManager - Comprehensive risk management and position sizing
    
    Provides methods for:
    - Value at Risk (VaR): Historical, Parametric, Monte Carlo
    - Conditional VaR (CVaR / Expected Shortfall)
    - Position sizing: Kelly Criterion, Fixed Fractional, Percent Volatility
    - Risk metrics: Sharpe, Sortino, Calmar, Maximum Drawdown
    - Stop loss calculations

!!! abstract "Source Information"
    **Defined in:** [`lib/sqa/risk_manager.rb:29`](https://github.com/madbomber/sqa/blob/main/lib/sqa/risk_manager.rb#L29)
    
    **Inherits from:** `Object`

## 🏭 Class Methods

### `.var(returns, confidence: = 0.95, method: = :historical, simulations: = 10_000)`

Calculate Value at Risk (VaR) using historical method

VaR represents the maximum expected loss over a given time period
at a specified confidence level.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `returns` | `Array<Float>` | Array of period returns (e.g., daily returns) |
    | `confidence` | `Float` | Confidence level (default: 0.95 for 95%) |
    | `method` | `Symbol` | Method to use (:historical, :parametric, :monte_carlo) |
    | `simulations` | `Integer` | Number of Monte Carlo simulations (if method is :monte_carlo) |
!!! success "Returns"

    **Type:** `Float`

    

    Value at Risk as a percentage
!!! example "Usage Examples"

    ```ruby
    returns = [0.01, -0.02, 0.015, -0.01, 0.005]
    var = SQA::RiskManager.var(returns, confidence: 0.95)
    # => -0.02 (2% maximum expected loss at 95% confidence)
    ```
??? info "Source Location"
    [`lib/sqa/risk_manager.rb:48`](https://github.com/madbomber/sqa/blob/main/lib/sqa/risk_manager.rb#L48)

---

### `.cvar(returns, confidence: = 0.95)`

Calculate Conditional Value at Risk (CVaR / Expected Shortfall)

CVaR is the expected loss given that the loss exceeds the VaR threshold.
It provides a more conservative risk measure than VaR.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `returns` | `Array<Float>` | Array of period returns |
    | `confidence` | `Float` | Confidence level (default: 0.95) |
!!! success "Returns"

    **Type:** `Float`

    

    CVaR as a percentage
!!! example "Usage Examples"

    ```ruby
    cvar = SQA::RiskManager.cvar(returns, confidence: 0.95)
    # => -0.025 (2.5% expected loss in worst 5% of cases)
    ```
??? info "Source Location"
    [`lib/sqa/risk_manager.rb:77`](https://github.com/madbomber/sqa/blob/main/lib/sqa/risk_manager.rb#L77)

---

### `.kelly_criterion(win_rate:, avg_win:, avg_loss:, capital:, max_fraction: = 0.25)`

Calculate position size using Kelly Criterion

Kelly Criterion calculates the optimal fraction of capital to risk
based on win rate and win/loss ratio.

Formula: f = (p * b - q) / b
where:
  f = fraction of capital to bet
  p = probability of winning
  q = probability of losing (1 - p)
  b = win/loss ratio (avg_win / avg_loss)

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `win_rate` | `Float` | Win rate (0.0 to 1.0) |
    | `avg_win` | `Float` | Average win size (as percentage) |
    | `avg_loss` | `Float` | Average loss size (as percentage) |
    | `capital` | `Float` | Total capital available |
    | `max_fraction` | `Float` | Maximum fraction to risk (default: 0.25 for 25%) |
!!! success "Returns"

    **Type:** `Float`

    

    Dollar amount to risk
!!! example "Usage Examples"

    ```ruby
    position = SQA::RiskManager.kelly_criterion(
      win_rate: 0.60,
      avg_win: 0.10,
      avg_loss: 0.05,
      capital: 10_000,
      max_fraction: 0.25
    )
    ```
??? info "Source Location"
    [`lib/sqa/risk_manager.rb:116`](https://github.com/madbomber/sqa/blob/main/lib/sqa/risk_manager.rb#L116)

---

### `.fixed_fractional(capital:, risk_fraction: = 0.02)`

Calculate position size using Fixed Fractional method

Risk a fixed percentage of capital on each trade.
Simple and conservative approach.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `capital` | `Float` | Total capital |
    | `risk_fraction` | `Float` | Fraction to risk (e.g., 0.02 for 2%) |
!!! success "Returns"

    **Type:** `Float`

    

    Dollar amount to risk
!!! example "Usage Examples"

    ```ruby
    position = SQA::RiskManager.fixed_fractional(capital: 10_000, risk_fraction: 0.02)
    # => 200.0 (risk $200 per trade)
    ```
??? info "Source Location"
    [`lib/sqa/risk_manager.rb:146`](https://github.com/madbomber/sqa/blob/main/lib/sqa/risk_manager.rb#L146)

---

### `.percent_volatility(capital:, returns:, target_volatility: = 0.15, current_price:)`

Calculate position size using Percent Volatility method

Adjust position size based on recent volatility.
Higher volatility = smaller position size.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `capital` | `Float` | Total capital |
    | `returns` | `Array<Float>` | Recent returns |
    | `target_volatility` | `Float` | Target portfolio volatility (annualized) |
    | `current_price` | `Float` | Current asset price |
!!! success "Returns"

    **Type:** `Integer`

    

    Number of shares to buy
!!! example "Usage Examples"

    ```ruby
    shares = SQA::RiskManager.percent_volatility(
      capital: 10_000,
      returns: recent_returns,
      target_volatility: 0.15,
      current_price: 150.0
    )
    ```
??? info "Source Location"
    [`lib/sqa/risk_manager.rb:170`](https://github.com/madbomber/sqa/blob/main/lib/sqa/risk_manager.rb#L170)

---

### `.atr_stop_loss(current_price:, atr:, multiplier: = 2.0, direction: = :long)`

Calculate stop loss price based on ATR (Average True Range)

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `current_price` | `Float` | Current asset price |
    | `atr` | `Float` | Average True Range |
    | `multiplier` | `Float` | ATR multiplier (default: 2.0) |
    | `direction` | `Symbol` | :long or :short |
!!! success "Returns"

    **Type:** `Float`

    

    Stop loss price
!!! example "Usage Examples"

    ```ruby
    stop = SQA::RiskManager.atr_stop_loss(
      current_price: 150.0,
      atr: 3.5,
      multiplier: 2.0,
      direction: :long
    )
    # => 143.0 (stop at current - 2*ATR)
    ```
??? info "Source Location"
    [`lib/sqa/risk_manager.rb:204`](https://github.com/madbomber/sqa/blob/main/lib/sqa/risk_manager.rb#L204)

---

### `.max_drawdown(prices)`

Calculate maximum drawdown from price series

Drawdown is the peak-to-trough decline in portfolio value.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `prices` | `Array<Float>` | Array of prices or portfolio values |
!!! success "Returns"

    **Type:** `Hash`

    

    { max_drawdown: Float, peak_idx: Integer, trough_idx: Integer }
!!! example "Usage Examples"

    ```ruby
    dd = SQA::RiskManager.max_drawdown([100, 110, 105, 95, 100])
    # => { max_drawdown: -0.136, peak_idx: 1, trough_idx: 3 }
    ```
??? info "Source Location"
    [`lib/sqa/risk_manager.rb:224`](https://github.com/madbomber/sqa/blob/main/lib/sqa/risk_manager.rb#L224)

---

### `.sharpe_ratio(returns, risk_free_rate: = 0.02, periods_per_year: = 252)`

Calculate Sharpe Ratio

Measures risk-adjusted return (excess return per unit of risk).

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `returns` | `Array<Float>` | Array of period returns |
    | `risk_free_rate` | `Float` | Risk-free rate (annualized, default: 0.02) |
    | `periods_per_year` | `Integer` | Number of periods per year (default: 252 for daily) |
!!! success "Returns"

    **Type:** `Float`

    

    Sharpe ratio
!!! example "Usage Examples"

    ```ruby
    sharpe = SQA::RiskManager.sharpe_ratio(returns, risk_free_rate: 0.02)
    ```
??? info "Source Location"
    [`lib/sqa/risk_manager.rb:269`](https://github.com/madbomber/sqa/blob/main/lib/sqa/risk_manager.rb#L269)

---

### `.sortino_ratio(returns, target_return: = 0.0, periods_per_year: = 252)`

Calculate Sortino Ratio

Like Sharpe ratio but only penalizes downside volatility.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `returns` | `Array<Float>` | Array of period returns |
    | `target_return` | `Float` | Target return (default: 0.0) |
    | `periods_per_year` | `Integer` | Number of periods per year (default: 252) |
!!! success "Returns"

    **Type:** `Float`

    

    Sortino ratio
!!! example "Usage Examples"

    ```ruby
    sortino = SQA::RiskManager.sortino_ratio(returns)
    ```
??? info "Source Location"
    [`lib/sqa/risk_manager.rb:294`](https://github.com/madbomber/sqa/blob/main/lib/sqa/risk_manager.rb#L294)

---

### `.calmar_ratio(returns, periods_per_year: = 252)`

Calculate Calmar Ratio

Ratio of annualized return to maximum drawdown.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `returns` | `Array<Float>` | Array of period returns |
    | `periods_per_year` | `Integer` | Number of periods per year (default: 252) |
!!! success "Returns"

    **Type:** `Float`

    

    Calmar ratio
!!! example "Usage Examples"

    ```ruby
    calmar = SQA::RiskManager.calmar_ratio(returns)
    ```
??? info "Source Location"
    [`lib/sqa/risk_manager.rb:325`](https://github.com/madbomber/sqa/blob/main/lib/sqa/risk_manager.rb#L325)

---

### `.monte_carlo_simulation(initial_capital:, returns:, periods:, simulations: = 1000)`

Monte Carlo simulation for portfolio value

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `initial_capital` | `Float` | Starting capital |
    | `returns` | `Array<Float>` | Historical returns to sample from |
    | `periods` | `Integer` | Number of periods to simulate |
    | `simulations` | `Integer` | Number of simulation paths |
!!! success "Returns"

    **Type:** `Hash`

    

    Simulation results with percentiles
!!! example "Usage Examples"

    ```ruby
    results = SQA::RiskManager.monte_carlo_simulation(
      initial_capital: 10_000,
      returns: historical_returns,
      periods: 252,
      simulations: 1000
    )
    puts "95th percentile: $#{results[:percentile_95]}"
    ```
??? info "Source Location"
    [`lib/sqa/risk_manager.rb:360`](https://github.com/madbomber/sqa/blob/main/lib/sqa/risk_manager.rb#L360)

---

## 📝 Attributes

