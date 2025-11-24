# 📦 SQA::StrategyGenerator

!!! abstract "Source Information"
    **Defined in:** `lib/sqa/strategy_generator.rb:36`
    
    **Inherits from:** `Object`

## 🔨 Instance Methods

### `#stock()`

Returns the value of attribute stock.




??? info "Source Location"
    `lib/sqa/strategy_generator.rb:140`

---

### `#profitable_points()`

Returns the value of attribute profitable_points.




??? info "Source Location"
    `lib/sqa/strategy_generator.rb:140`

---

### `#patterns()`

Returns the value of attribute patterns.




??? info "Source Location"
    `lib/sqa/strategy_generator.rb:140`

---

### `#min_gain_percent()`

Returns the value of attribute min_gain_percent.




??? info "Source Location"
    `lib/sqa/strategy_generator.rb:140`

---

### `#fpop()`

Returns the value of attribute fpop.




??? info "Source Location"
    `lib/sqa/strategy_generator.rb:140`

---

### `#min_loss_percent()`

Returns the value of attribute min_loss_percent.




??? info "Source Location"
    `lib/sqa/strategy_generator.rb:140`

---

### `#indicators_config()`

Returns the value of attribute indicators_config.




??? info "Source Location"
    `lib/sqa/strategy_generator.rb:140`

---

### `#inflection_window()`

Returns the value of attribute inflection_window.




??? info "Source Location"
    `lib/sqa/strategy_generator.rb:140`

---

### `#max_fpl_risk()`

Returns the value of attribute max_fpl_risk.




??? info "Source Location"
    `lib/sqa/strategy_generator.rb:140`

---

### `#required_fpl_directions()`

Returns the value of attribute required_fpl_directions.




??? info "Source Location"
    `lib/sqa/strategy_generator.rb:140`

---

### `#initialize(stock:, min_gain_percent: = 10.0, min_loss_percent: = nil, fpop: = 10, inflection_window: = 3, max_fpl_risk: = nil, required_fpl_directions: = nil)`


!!! success "Returns"

    **Type:** `StrategyGenerator`

    

    a new instance of StrategyGenerator

??? info "Source Location"
    `lib/sqa/strategy_generator.rb:144`

---

### `#discover_patterns(min_pattern_frequency: = 2)`

Main entry point: Discover patterns in historical data




??? info "Source Location"
    `lib/sqa/strategy_generator.rb:168`

---

### `#generate_strategy(pattern_index: = 0, strategy_type: = :proc)`

Generate a trading strategy from discovered patterns




??? info "Source Location"
    `lib/sqa/strategy_generator.rb:196`

---

### `#generate_strategies(top_n: = 5, strategy_type: = :class)`

Generate multiple strategies from top N patterns




??? info "Source Location"
    `lib/sqa/strategy_generator.rb:214`

---

### `#print_patterns(max_patterns: = 10)`

Print discovered patterns




??? info "Source Location"
    `lib/sqa/strategy_generator.rb:221`

---

### `#export_patterns(filename)`

Export patterns to CSV




??? info "Source Location"
    `lib/sqa/strategy_generator.rb:241`

---

### `#walk_forward_validate(train_size: = 250, test_size: = 60, step_size: = 30)`

Walk-forward validation - discover patterns with time-series cross-validation

Splits data into train/test windows and rolls forward through history
to prevent overfitting. Only keeps patterns that work out-of-sample.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `train_size` | `Integer` | Training window size in days |
    | `test_size` | `Integer` | Testing window size in days |
    | `step_size` | `Integer` | How many days to step forward each iteration |
!!! success "Returns"

    **Type:** `Hash`

    

    Validation results with patterns and performance

??? info "Source Location"
    `lib/sqa/strategy_generator.rb:273`

---

### `#discover_context_aware_patterns(analyze_regime: = true, analyze_seasonal: = true, sector: = nil)`

Discover patterns with context (regime, seasonal, sector)

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `analyze_regime` | `Boolean` | Detect and filter by market regime |
    | `analyze_seasonal` | `Boolean` | Detect seasonal patterns |
    | `sector` | `Symbol` | Sector classification |
!!! success "Returns"

    **Type:** `Array<Pattern>`

    

    Patterns with context metadata

??? info "Source Location"
    `lib/sqa/strategy_generator.rb:379`

---

## 📝 Attributes

### 👁️ `stock` <small>read-only</small>

Returns the value of attribute stock.

### 👁️ `profitable_points` <small>read-only</small>

Returns the value of attribute profitable_points.

### 👁️ `patterns` <small>read-only</small>

Returns the value of attribute patterns.

### 👁️ `min_gain_percent` <small>read-only</small>

Returns the value of attribute min_gain_percent.

### 👁️ `fpop` <small>read-only</small>

Returns the value of attribute fpop.

### 👁️ `min_loss_percent` <small>read-only</small>

Returns the value of attribute min_loss_percent.

### 👁️ `indicators_config` <small>read-only</small>

Returns the value of attribute indicators_config.

### 👁️ `inflection_window` <small>read-only</small>

Returns the value of attribute inflection_window.

### 👁️ `max_fpl_risk` <small>read-only</small>

Returns the value of attribute max_fpl_risk.

### 👁️ `required_fpl_directions` <small>read-only</small>

Returns the value of attribute required_fpl_directions.

