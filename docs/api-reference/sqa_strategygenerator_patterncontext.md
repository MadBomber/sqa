# 📦 SQA::StrategyGenerator::PatternContext

!!! note "Description"
    Pattern Context - metadata about when/where pattern is valid

!!! abstract "Source Information"
    **Defined in:** [`lib/sqa/strategy_generator.rb:91`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L91)
    
    **Inherits from:** `Object`

## 🔨 Instance Methods

### `#market_regime()`

Returns the value of attribute market_regime.




??? info "Source Location"
    [`lib/sqa/strategy_generator.rb:92`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L92)

---

### `#market_regime=(value)`

Sets the attribute market_regime

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute market_regime to. |


??? info "Source Location"
    [`lib/sqa/strategy_generator.rb:92`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L92)

---

### `#valid_months()`

Returns the value of attribute valid_months.




??? info "Source Location"
    [`lib/sqa/strategy_generator.rb:92`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L92)

---

### `#valid_months=(value)`

Sets the attribute valid_months

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute valid_months to. |


??? info "Source Location"
    [`lib/sqa/strategy_generator.rb:92`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L92)

---

### `#valid_quarters()`

Returns the value of attribute valid_quarters.




??? info "Source Location"
    [`lib/sqa/strategy_generator.rb:92`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L92)

---

### `#valid_quarters=(value)`

Sets the attribute valid_quarters

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute valid_quarters to. |


??? info "Source Location"
    [`lib/sqa/strategy_generator.rb:92`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L92)

---

### `#discovered_period()`

Returns the value of attribute discovered_period.




??? info "Source Location"
    [`lib/sqa/strategy_generator.rb:92`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L92)

---

### `#discovered_period=(value)`

Sets the attribute discovered_period

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute discovered_period to. |


??? info "Source Location"
    [`lib/sqa/strategy_generator.rb:92`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L92)

---

### `#validation_period()`

Returns the value of attribute validation_period.




??? info "Source Location"
    [`lib/sqa/strategy_generator.rb:92`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L92)

---

### `#validation_period=(value)`

Sets the attribute validation_period

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute validation_period to. |


??? info "Source Location"
    [`lib/sqa/strategy_generator.rb:92`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L92)

---

### `#stability_score()`

Returns the value of attribute stability_score.




??? info "Source Location"
    [`lib/sqa/strategy_generator.rb:92`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L92)

---

### `#stability_score=(value)`

Sets the attribute stability_score

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute stability_score to. |


??? info "Source Location"
    [`lib/sqa/strategy_generator.rb:92`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L92)

---

### `#sector()`

Returns the value of attribute sector.




??? info "Source Location"
    [`lib/sqa/strategy_generator.rb:92`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L92)

---

### `#sector=(value)`

Sets the attribute sector

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute sector to. |


??? info "Source Location"
    [`lib/sqa/strategy_generator.rb:92`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L92)

---

### `#volatility_regime()`

Returns the value of attribute volatility_regime.




??? info "Source Location"
    [`lib/sqa/strategy_generator.rb:92`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L92)

---

### `#volatility_regime=(value)`

Sets the attribute volatility_regime

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute volatility_regime to. |


??? info "Source Location"
    [`lib/sqa/strategy_generator.rb:92`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L92)

---

### `#initialize()`


!!! success "Returns"

    **Type:** `PatternContext`

    

    a new instance of PatternContext

??? info "Source Location"
    [`lib/sqa/strategy_generator.rb:96`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L96)

---

### `#valid?()`


!!! success "Returns"

    **Type:** `Boolean`

    

??? info "Source Location"
    [`lib/sqa/strategy_generator.rb:107`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L107)

---

### `#summary()`




??? info "Source Location"
    [`lib/sqa/strategy_generator.rb:111`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L111)

---

### `#valid_for?(date: = nil, regime: = nil, sector: = nil)`

Check if pattern is valid for given date and conditions


!!! success "Returns"

    **Type:** `Boolean`

    

??? info "Source Location"
    [`lib/sqa/strategy_generator.rb:121`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy_generator.rb#L121)

---

## 📝 Attributes

### 🔄 `market_regime` <small>read/write</small>

Returns the value of attribute market_regime.

### 🔄 `valid_months` <small>read/write</small>

Returns the value of attribute valid_months.

### 🔄 `valid_quarters` <small>read/write</small>

Returns the value of attribute valid_quarters.

### 🔄 `discovered_period` <small>read/write</small>

Returns the value of attribute discovered_period.

### 🔄 `validation_period` <small>read/write</small>

Returns the value of attribute validation_period.

### 🔄 `stability_score` <small>read/write</small>

Returns the value of attribute stability_score.

### 🔄 `sector` <small>read/write</small>

Returns the value of attribute sector.

### 🔄 `volatility_regime` <small>read/write</small>

Returns the value of attribute volatility_regime.

