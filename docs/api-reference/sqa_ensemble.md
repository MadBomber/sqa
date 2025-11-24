# 📦 SQA::Ensemble

!!! note "Description"
    Ensemble - Combine multiple trading strategies
    
    Provides methods for:
    - Majority voting
    - Weighted voting based on past performance
    - Meta-learning (strategy selection)
    - Strategy rotation based on market conditions
    - Confidence-based aggregation

!!! abstract "Source Information"
    **Defined in:** `lib/sqa/ensemble.rb:22`
    
    **Inherits from:** `Object`

## 🏭 Class Methods

### `.trade(vector)`

Make ensemble compatible with Backtest (acts like a strategy)

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `vector` | `OpenStruct` | Market data |
!!! success "Returns"

    **Type:** `Symbol`

    

    Trading signal

??? info "Source Location"
    `lib/sqa/ensemble.rb:275`

---

## 🔨 Instance Methods

### `#strategies()`

Returns the value of attribute strategies.




??? info "Source Location"
    `lib/sqa/ensemble.rb:23`

---

### `#strategies=(value)`

Sets the attribute strategies

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute strategies to. |


??? info "Source Location"
    `lib/sqa/ensemble.rb:23`

---

### `#weights()`

Returns the value of attribute weights.




??? info "Source Location"
    `lib/sqa/ensemble.rb:23`

---

### `#weights=(value)`

Sets the attribute weights

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute weights to. |


??? info "Source Location"
    `lib/sqa/ensemble.rb:23`

---

### `#performance_history()`

Returns the value of attribute performance_history.




??? info "Source Location"
    `lib/sqa/ensemble.rb:23`

---

### `#performance_history=(value)`

Sets the attribute performance_history

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute performance_history to. |


??? info "Source Location"
    `lib/sqa/ensemble.rb:23`

---

### `#initialize(strategies:, voting_method: = :majority, weights: = nil)`

Initialize ensemble

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `strategies` | `Array<Class>` | Array of strategy classes |
    | `voting_method` | `Symbol` | :majority, :weighted, :unanimous, :confidence |
    | `weights` | `Array<Float>` | Optional weights for weighted voting |
!!! success "Returns"

    **Type:** `Ensemble`

    

    a new instance of Ensemble

??? info "Source Location"
    `lib/sqa/ensemble.rb:32`

---

### `#signal(vector)`

Generate ensemble signal

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `vector` | `OpenStruct` | Market data vector |
!!! success "Returns"

    **Type:** `Symbol`

    

    :buy, :sell, or :hold

??? info "Source Location"
    `lib/sqa/ensemble.rb:46`

---

### `#majority_vote(vector)`

Majority voting

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `vector` | `OpenStruct` | Market data |
!!! success "Returns"

    **Type:** `Symbol`

    

    Signal with most votes

??? info "Source Location"
    `lib/sqa/ensemble.rb:67`

---

### `#weighted_vote(vector)`

Weighted voting based on strategy performance

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `vector` | `OpenStruct` | Market data |
!!! success "Returns"

    **Type:** `Symbol`

    

    Weighted signal

??? info "Source Location"
    `lib/sqa/ensemble.rb:84`

---

### `#unanimous_vote(vector)`

Unanimous voting (all strategies must agree)

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `vector` | `OpenStruct` | Market data |
!!! success "Returns"

    **Type:** `Symbol`

    

    :buy/:sell only if unanimous, otherwise :hold

??? info "Source Location"
    `lib/sqa/ensemble.rb:104`

---

### `#confidence_vote(vector)`

Confidence-based voting

Weight votes by strategy confidence scores.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `vector` | `OpenStruct` | Market data |
!!! success "Returns"

    **Type:** `Symbol`

    

    Signal weighted by confidence

??? info "Source Location"
    `lib/sqa/ensemble.rb:125`

---

### `#update_weight(strategy_index, performance)`

Update strategy weights based on performance

Adjust weights to favor better-performing strategies.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `strategy_index` | `Integer` | Index of strategy |
    | `performance` | `Float` | Performance metric (e.g., return) |


??? info "Source Location"
    `lib/sqa/ensemble.rb:147`

---

### `#update_confidence(strategy_class, correct)`

Update confidence score for strategy

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `strategy_class` | `Class` | Strategy class |
    | `correct` | `Boolean` | Was the prediction correct? |


??? info "Source Location"
    `lib/sqa/ensemble.rb:160`

---

### `#select_strategy(market_regime:, volatility: = :medium)`

Select best strategy for current market conditions

Meta-learning approach: choose the strategy most likely to succeed.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `market_regime` | `Symbol` | Current market regime (:bull, :bear, :sideways) |
    | `volatility` | `Symbol` | Volatility regime (:low, :medium, :high) |
!!! success "Returns"

    **Type:** `Class`

    

    Best strategy class for conditions

??? info "Source Location"
    `lib/sqa/ensemble.rb:181`

---

### `#rotate(stock)`

Rotate strategies based on market conditions

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `stock` | `SQA::Stock` | Stock object |
!!! success "Returns"

    **Type:** `Class`

    

    Strategy to use

??? info "Source Location"
    `lib/sqa/ensemble.rb:213`

---

### `#statistics()`

Get ensemble statistics


!!! success "Returns"

    **Type:** `Hash`

    

    Performance statistics

??? info "Source Location"
    `lib/sqa/ensemble.rb:227`

---

### `#backtest_comparison(stock, initial_capital: = 10_000)`

Backtest ensemble vs individual strategies

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `stock` | `SQA::Stock` | Stock to backtest |
    | `initial_capital` | `Float` | Starting capital |
!!! success "Returns"

    **Type:** `Hash`

    

    Comparison results

??? info "Source Location"
    `lib/sqa/ensemble.rb:245`

---

### `#trade(vector)`

Instance method for compatibility




??? info "Source Location"
    `lib/sqa/ensemble.rb:283`

---

## 📝 Attributes

### 🔄 `strategies` <small>read/write</small>

Returns the value of attribute strategies.

### 🔄 `weights` <small>read/write</small>

Returns the value of attribute weights.

### 🔄 `performance_history` <small>read/write</small>

Returns the value of attribute performance_history.

