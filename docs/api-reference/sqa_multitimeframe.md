# 📦 SQA::MultiTimeframe

!!! note "Description"
    MultiTimeframe - Analyze patterns across multiple timeframes
    
    Provides methods for:
    - Timeframe conversion (daily → weekly → monthly)
    - Multi-timeframe signal confirmation
    - Trend alignment across timeframes
    - Support/resistance across timeframes
    
    Common timeframe strategy:
    - Use higher timeframe for trend direction
    - Use lower timeframe for entry timing

!!! abstract "Source Information"
    **Defined in:** `lib/sqa/multi_timeframe.rb:23`
    
    **Inherits from:** `Object`

## 🔨 Instance Methods

### `#stock()`

Returns the value of attribute stock.




??? info "Source Location"
    `lib/sqa/multi_timeframe.rb:24`

---

### `#timeframes()`

Returns the value of attribute timeframes.




??? info "Source Location"
    `lib/sqa/multi_timeframe.rb:24`

---

### `#initialize(stock:)`

Initialize multi-timeframe analyzer

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `stock` | `SQA::Stock` | Stock object with daily data |
!!! success "Returns"

    **Type:** `MultiTimeframe`

    

    a new instance of MultiTimeframe

??? info "Source Location"
    `lib/sqa/multi_timeframe.rb:31`

---

### `#convert_timeframes()`

Convert daily data to weekly and monthly




??? info "Source Location"
    `lib/sqa/multi_timeframe.rb:42`

---

### `#trend_alignment(lookback: = 20)`

Check trend alignment across timeframes

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `lookback` | `Integer` | Periods to look back for trend |
!!! success "Returns"

    **Type:** `Hash`

    

    Trend direction for each timeframe

??? info "Source Location"
    `lib/sqa/multi_timeframe.rb:56`

---

### `#signal(strategy_class:, higher_timeframe: = :weekly, lower_timeframe: = :daily)`

Generate multi-timeframe signal

Uses higher timeframe for trend, lower for timing.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `strategy_class` | `Class` | Strategy to apply |
    | `higher_timeframe` | `Symbol` | Timeframe for trend (:weekly, :monthly) |
    | `lower_timeframe` | `Symbol` | Timeframe for entry (:daily, :weekly) |
!!! success "Returns"

    **Type:** `Symbol`

    

    :buy, :sell, or :hold

??? info "Source Location"
    `lib/sqa/multi_timeframe.rb:102`

---

### `#support_resistance(tolerance: = 0.02)`

Find support/resistance levels across timeframes

Levels that appear on multiple timeframes are stronger.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `tolerance` | `Float` | Price tolerance for matching levels (default: 0.02 for 2%) |
!!! success "Returns"

    **Type:** `Hash`

    

    Support and resistance levels

??? info "Source Location"
    `lib/sqa/multi_timeframe.rb:138`

---

### `#indicators(indicator:, **options)`

Calculate indicators for each timeframe

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `indicator` | `Symbol` | Indicator to calculate |
    | `options` | `Hash` | Indicator options |
!!! success "Returns"

    **Type:** `Hash`

    

    Indicator values for each timeframe

??? info "Source Location"
    `lib/sqa/multi_timeframe.rb:167`

---

### `#detect_divergence()`

Detect divergence across timeframes

Divergence occurs when price and indicator move in opposite directions.


!!! success "Returns"

    **Type:** `Hash`

    

    Divergence information

??? info "Source Location"
    `lib/sqa/multi_timeframe.rb:197`

---

### `#confirmation(strategy_class:)`

Check if timeframes confirm each other

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `strategy_class` | `Class` | Strategy to use |
!!! success "Returns"

    **Type:** `Hash`

    

    Confirmation status

??? info "Source Location"
    `lib/sqa/multi_timeframe.rb:228`

---

## 📝 Attributes

### 👁️ `stock` <small>read-only</small>

Returns the value of attribute stock.

### 👁️ `timeframes` <small>read-only</small>

Returns the value of attribute timeframes.

