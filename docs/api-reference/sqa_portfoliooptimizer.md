# 📦 SQA::PortfolioOptimizer

!!! note "Description"
    PortfolioOptimizer - Multi-objective portfolio optimization
    
    Provides methods for:
    - Mean-Variance Optimization (Markowitz)
    - Multi-objective optimization (return vs risk vs drawdown)
    - Efficient Frontier calculation
    - Risk Parity allocation
    - Minimum Variance portfolio
    - Maximum Sharpe portfolio

!!! abstract "Source Information"
    **Defined in:** [`lib/sqa/portfolio_optimizer.rb:25`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio_optimizer.rb#L25)
    
    **Inherits from:** `Object`

## 🏭 Class Methods

### `.portfolio_returns(returns_matrix, weights)`

Calculate portfolio returns given weights

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `returns_matrix` | `Array<Array<Float>>` | Returns for each asset (rows = assets, cols = periods) |
    | `weights` | `Array<Float>` | Portfolio weights (must sum to 1.0) |
!!! success "Returns"

    **Type:** `Array<Float>`

    

    Portfolio returns over time

??? info "Source Location"
    [`lib/sqa/portfolio_optimizer.rb:34`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio_optimizer.rb#L34)

---

### `.portfolio_variance(returns_matrix, weights)`

Calculate portfolio variance

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `returns_matrix` | `Array<Array<Float>>` | Returns for each asset |
    | `weights` | `Array<Float>` | Portfolio weights |
!!! success "Returns"

    **Type:** `Float`

    

    Portfolio variance

??? info "Source Location"
    [`lib/sqa/portfolio_optimizer.rb:51`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio_optimizer.rb#L51)

---

### `.maximum_sharpe(returns_matrix, risk_free_rate: = 0.02, constraints: = {})`

Find Maximum Sharpe Ratio portfolio

Uses numerical optimization to find weights that maximize Sharpe ratio.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `returns_matrix` | `Array<Array<Float>>` | Returns for each asset |
    | `risk_free_rate` | `Float` | Risk-free rate (default: 0.02) |
    | `constraints` | `Hash` | Optimization constraints |
!!! success "Returns"

    **Type:** `Hash`

    

    { weights: Array, sharpe: Float, return: Float, volatility: Float }

??? info "Source Location"
    [`lib/sqa/portfolio_optimizer.rb:75`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio_optimizer.rb#L75)

---

### `.minimum_variance(returns_matrix, constraints: = {})`

Find Minimum Variance portfolio

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `returns_matrix` | `Array<Array<Float>>` | Returns for each asset |
    | `constraints` | `Hash` | Optimization constraints |
!!! success "Returns"

    **Type:** `Hash`

    

    { weights: Array, variance: Float, volatility: Float }

??? info "Source Location"
    [`lib/sqa/portfolio_optimizer.rb:114`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio_optimizer.rb#L114)

---

### `.risk_parity(returns_matrix)`

Calculate Risk Parity portfolio

Allocate weights so each asset contributes equally to portfolio risk.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `returns_matrix` | `Array<Array<Float>>` | Returns for each asset |
!!! success "Returns"

    **Type:** `Hash`

    

    { weights: Array, volatility: Float }

??? info "Source Location"
    [`lib/sqa/portfolio_optimizer.rb:146`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio_optimizer.rb#L146)

---

### `.efficient_frontier(returns_matrix, num_portfolios: = 50)`

Calculate Efficient Frontier

Generate portfolios along the efficient frontier.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `returns_matrix` | `Array<Array<Float>>` | Returns for each asset |
    | `num_portfolios` | `Integer` | Number of portfolios to generate |
!!! success "Returns"

    **Type:** `Array<Hash>`

    

    Array of portfolio hashes

??? info "Source Location"
    [`lib/sqa/portfolio_optimizer.rb:175`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio_optimizer.rb#L175)

---

### `.multi_objective(returns_matrix, objectives: = {})`

Multi-objective optimization

Optimize portfolio for multiple objectives simultaneously.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `returns_matrix` | `Array<Array<Float>>` | Returns for each asset |
    | `objectives` | `Hash` | Objectives with weights |
!!! success "Returns"

    **Type:** `Hash`

    

    Optimal portfolio
!!! example "Usage Examples"

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
??? info "Source Location"
    [`lib/sqa/portfolio_optimizer.rb:217`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio_optimizer.rb#L217)

---

### `.equal_weight(num_assets)`

Equal weight portfolio (1/N rule)

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `num_assets` | `Integer` | Number of assets |
!!! success "Returns"

    **Type:** `Array<Float>`

    

    Equal weights

??? info "Source Location"
    [`lib/sqa/portfolio_optimizer.rb:285`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio_optimizer.rb#L285)

---

### `.rebalance(current_values:, target_weights:, total_value:, prices:)`

Rebalance portfolio to target weights

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `current_values` | `Hash` | Current holdings { ticker => value } |
    | `target_weights` | `Hash` | Target weights { ticker => weight } |
    | `total_value` | `Float` | Total portfolio value |
!!! success "Returns"

    **Type:** `Hash`

    

    Rebalancing trades { ticker => { action: :buy/:sell, shares: N, value: $ } }

??? info "Source Location"
    [`lib/sqa/portfolio_optimizer.rb:298`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio_optimizer.rb#L298)

---

## 📝 Attributes

