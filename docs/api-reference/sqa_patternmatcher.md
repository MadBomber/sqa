# 📦 SQA::PatternMatcher

!!! note "Description"
    PatternMatcher - Find similar historical patterns
    
    Provides methods for:
    - Pattern similarity search (nearest-neighbor)
    - Shape-based pattern matching
    - Predict future moves based on similar past patterns
    - Pattern clustering
    
    Uses techniques:
    - Euclidean distance
    - Dynamic Time Warping (DTW)
    - Pearson correlation

!!! abstract "Source Information"
    **Defined in:** [`lib/sqa/pattern_matcher.rb:24`](https://github.com/madbomber/sqa/blob/main/lib/sqa/pattern_matcher.rb#L24)
    
    **Inherits from:** `Object`

## 🔨 Instance Methods

### `#stock()`

Returns the value of attribute stock.




??? info "Source Location"
    [`lib/sqa/pattern_matcher.rb:25`](https://github.com/madbomber/sqa/blob/main/lib/sqa/pattern_matcher.rb#L25)

---

### `#prices()`

Returns the value of attribute prices.




??? info "Source Location"
    [`lib/sqa/pattern_matcher.rb:25`](https://github.com/madbomber/sqa/blob/main/lib/sqa/pattern_matcher.rb#L25)

---

### `#initialize(stock:)`

Initialize pattern matcher

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `stock` | `SQA::Stock` | Stock object |
!!! success "Returns"

    **Type:** `PatternMatcher`

    

    a new instance of PatternMatcher

??? info "Source Location"
    [`lib/sqa/pattern_matcher.rb:32`](https://github.com/madbomber/sqa/blob/main/lib/sqa/pattern_matcher.rb#L32)

---

### `#find_similar(lookback: = 10, num_matches: = 5, method: = :euclidean, normalize: = true)`

Find similar historical patterns to current pattern

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `lookback` | `Integer` | Pattern length (days) |
    | `num_matches` | `Integer` | Number of similar patterns to find |
    | `method` | `Symbol` | Distance method (:euclidean, :dtw, :correlation) |
    | `normalize` | `Boolean` | Normalize patterns before comparison |
!!! success "Returns"

    **Type:** `Array<Hash>`

    

    Similar patterns with metadata

??? info "Source Location"
    [`lib/sqa/pattern_matcher.rb:46`](https://github.com/madbomber/sqa/blob/main/lib/sqa/pattern_matcher.rb#L46)

---

### `#forecast(lookback: = 10, forecast_periods: = 5, num_matches: = 10)`

Predict future price movement based on similar patterns

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `lookback` | `Integer` | Pattern length |
    | `forecast_periods` | `Integer` | Periods to forecast |
    | `num_matches` | `Integer` | Number of similar patterns to use |
!!! success "Returns"

    **Type:** `Hash`

    

    Forecast with confidence intervals

??? info "Source Location"
    [`lib/sqa/pattern_matcher.rb:107`](https://github.com/madbomber/sqa/blob/main/lib/sqa/pattern_matcher.rb#L107)

---

### `#detect_chart_pattern(pattern_type)`

Detect chart patterns (head & shoulders, double top, etc.)

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `pattern_type` | `Symbol` | Pattern to detect |
!!! success "Returns"

    **Type:** `Array<Hash>`

    

    Detected patterns

??? info "Source Location"
    [`lib/sqa/pattern_matcher.rb:141`](https://github.com/madbomber/sqa/blob/main/lib/sqa/pattern_matcher.rb#L141)

---

### `#cluster_patterns(pattern_length: = 10, num_clusters: = 5)`

Cluster patterns by similarity

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `pattern_length` | `Integer` | Length of patterns |
    | `num_clusters` | `Integer` | Number of clusters |
!!! success "Returns"

    **Type:** `Array<Array<Hash>>`

    

    Clusters of similar patterns

??? info "Source Location"
    [`lib/sqa/pattern_matcher.rb:163`](https://github.com/madbomber/sqa/blob/main/lib/sqa/pattern_matcher.rb#L163)

---

### `#pattern_quality(pattern)`

Calculate pattern strength/quality

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `pattern` | `Array<Float>` | Price pattern |
!!! success "Returns"

    **Type:** `Hash`

    

    Pattern quality metrics

??? info "Source Location"
    [`lib/sqa/pattern_matcher.rb:214`](https://github.com/madbomber/sqa/blob/main/lib/sqa/pattern_matcher.rb#L214)

---

## 📝 Attributes

### 👁️ `stock` <small>read-only</small>

Returns the value of attribute stock.

### 👁️ `prices` <small>read-only</small>

Returns the value of attribute prices.

