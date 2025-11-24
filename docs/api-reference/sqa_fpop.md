# 🔧 SQA::FPOP

!!! abstract "Source Information"
    **Defined in:** [`lib/sqa/fpop.rb:28`](https://github.com/madbomber/sqa/blob/main/lib/sqa/fpop.rb#L28)

## 🏭 Class Methods

### `.fpl(price, fpop: = 14)`

Calculate Future Period Loss/Profit for each point in price series

For each price point, looks ahead fpop periods and calculates:
- Minimum percentage change (worst loss)
- Maximum percentage change (best gain)

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `price` | `Array<Numeric>` | Array of prices |
    | `fpop` | `Integer` | Future Period of Performance (days to look ahead) |
!!! success "Returns"

    **Type:** `Array<Array<Float, Float>>`

    

    Array of [min_delta, max_delta] pairs
!!! example "Usage Examples"

    ```ruby
    SQA::FPOP.fpl([100, 105, 95, 110], fpop: 2)
    # => [[-5.0, 5.0], [-9.52, 4.76], [15.79, 15.79]]
    ```
??? info "Source Location"
    [`lib/sqa/fpop.rb:44`](https://github.com/madbomber/sqa/blob/main/lib/sqa/fpop.rb#L44)

---

### `.fpl_analysis(price, fpop: = 14)`

Perform comprehensive FPL analysis with risk metrics and classification

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `price` | `Array<Numeric>` | Array of prices |
    | `fpop` | `Integer` | Future Period of Performance |
!!! success "Returns"

    **Type:** `Array<Hash>`

    

    Array of analysis hashes containing:
- :min_delta - Worst percentage loss during fpop
- :max_delta - Best percentage gain during fpop
- :risk - Volatility range (max - min)
- :direction - Movement classification (:UP, :DOWN, :UNCERTAIN, :FLAT)
- :magnitude - Average expected movement
- :interpretation - Human-readable summary
!!! example "Usage Examples"

    ```ruby
    analysis = SQA::FPOP.fpl_analysis([100, 110, 120], fpop: 2)
    analysis.first
    # => {
    #   min_delta: 10.0,
    #   max_delta: 20.0,
    #   risk: 10.0,
    #   direction: :UP,
    #   magnitude: 15.0,
    #   interpretation: "UP: 15.0% (±5.0% risk)"
    # }
    ```
??? info "Source Location"
    [`lib/sqa/fpop.rb:85`](https://github.com/madbomber/sqa/blob/main/lib/sqa/fpop.rb#L85)

---

### `.determine_direction(min_delta, max_delta)`

Determine directional bias from min/max deltas

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `min_delta` | `Float` | Minimum percentage change |
    | `max_delta` | `Float` | Maximum percentage change |
!!! success "Returns"

    **Type:** `Symbol`

    

    :UP, :DOWN, :UNCERTAIN, or :FLAT

??? info "Source Location"
    [`lib/sqa/fpop.rb:108`](https://github.com/madbomber/sqa/blob/main/lib/sqa/fpop.rb#L108)

---

### `.calculate_magnitude(min_delta, max_delta)`

Calculate average expected movement (magnitude)

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `min_delta` | `Float` | Minimum percentage change |
    | `max_delta` | `Float` | Maximum percentage change |
!!! success "Returns"

    **Type:** `Float`

    

    Average of min and max deltas

??? info "Source Location"
    [`lib/sqa/fpop.rb:126`](https://github.com/madbomber/sqa/blob/main/lib/sqa/fpop.rb#L126)

---

### `.build_interpretation(min_delta, max_delta)`

Build human-readable interpretation string

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `min_delta` | `Float` | Minimum percentage change |
    | `max_delta` | `Float` | Maximum percentage change |
!!! success "Returns"

    **Type:** `String`

    

    Formatted interpretation

??? info "Source Location"
    [`lib/sqa/fpop.rb:136`](https://github.com/madbomber/sqa/blob/main/lib/sqa/fpop.rb#L136)

---

### `.filter_by_quality(analysis, min_magnitude: = nil, max_risk: = nil, directions: = [:UP, :DOWN, :UNCERTAIN, :FLAT])`

Filter FPL analysis results by criteria

Useful for finding high-quality trading opportunities

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `analysis` | `Array<Hash>` | FPL analysis results |
    | `min_magnitude` | `Float` | Minimum average movement (default: nil) |
    | `max_risk` | `Float` | Maximum acceptable risk (default: nil) |
    | `directions` | `Array<Symbol>` | Acceptable directions (default: [:UP, :DOWN, :UNCERTAIN, :FLAT]) |
!!! success "Returns"

    **Type:** `Array<Integer>`

    

    Indices of points that meet criteria
!!! example "Usage Examples"

    ```ruby
    analysis = SQA::FPOP.fpl_analysis(prices, fpop: 10)
    indices = SQA::FPOP.filter_by_quality(
      analysis,
      min_magnitude: 5.0,
      max_risk: 10.0,
      directions: [:UP]
    )
    ```
??? info "Source Location"
    [`lib/sqa/fpop.rb:163`](https://github.com/madbomber/sqa/blob/main/lib/sqa/fpop.rb#L163)

---

### `.risk_reward_ratios(analysis)`

Calculate risk-reward ratio for each analysis point

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `analysis` | `Array<Hash>` | FPL analysis results |
!!! success "Returns"

    **Type:** `Array<Float>`

    

    Risk-reward ratios (magnitude / risk)

??? info "Source Location"
    [`lib/sqa/fpop.rb:182`](https://github.com/madbomber/sqa/blob/main/lib/sqa/fpop.rb#L182)

---

## 📝 Attributes

