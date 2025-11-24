# 🔧 SQA::MarketRegime

!!! abstract "Source Information"
    **Defined in:** `lib/sqa/market_regime.rb:17`

## 🏭 Class Methods

### `.detect(stock, lookback: = nil, window: = nil)`

Detect current market regime for a stock

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `stock` | `SQA::Stock` | Stock to analyze |
    | `lookback` | `Integer` | Days to look back for regime detection |
    | `window` | `Integer` | Alias for lookback (for backward compatibility) |
!!! success "Returns"

    **Type:** `Hash`

    

    Regime metadata with both symbolic and numeric values

??? info "Source Location"
    `lib/sqa/market_regime.rb:26`

---

### `.detect_history(stock, window: = 60)`

Detect market regimes across entire history

Splits historical data into regime periods

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `stock` | `SQA::Stock` | Stock to analyze |
    | `window` | `Integer` | Rolling window for regime detection |
!!! success "Returns"

    **Type:** `Array<Hash>`

    

    Array of regime periods

??? info "Source Location"
    `lib/sqa/market_regime.rb:61`

---

### `.detect_trend_with_score(prices)`

Classify regime type based on trend with numeric score

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `prices` | `Array<Float>` | Price array |
!!! success "Returns"

    **Type:** `Hash`

    

    { type: Symbol, score: Float }

??? info "Source Location"
    `lib/sqa/market_regime.rb:109`

---

### `.detect_trend(prices)`

Classify regime type based on trend (backward compatibility)

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `prices` | `Array<Float>` | Price array |
!!! success "Returns"

    **Type:** `Symbol`

    

    :bull, :bear, or :sideways

??? info "Source Location"
    `lib/sqa/market_regime.rb:136`

---

### `.detect_volatility_with_score(prices)`

Detect volatility regime with numeric score

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `prices` | `Array<Float>` | Price array |
!!! success "Returns"

    **Type:** `Hash`

    

    { type: Symbol, score: Float }

??? info "Source Location"
    `lib/sqa/market_regime.rb:145`

---

### `.detect_volatility(prices)`

Detect volatility regime (backward compatibility)

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `prices` | `Array<Float>` | Price array |
!!! success "Returns"

    **Type:** `Symbol`

    

    :low, :medium, or :high

??? info "Source Location"
    `lib/sqa/market_regime.rb:170`

---

### `.detect_strength_with_score(prices)`

Detect trend strength with numeric score

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `prices` | `Array<Float>` | Price array |
!!! success "Returns"

    **Type:** `Hash`

    

    { type: Symbol, score: Float }

??? info "Source Location"
    `lib/sqa/market_regime.rb:179`

---

### `.detect_strength(prices)`

Detect trend strength (backward compatibility)

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `prices` | `Array<Float>` | Price array |
!!! success "Returns"

    **Type:** `Symbol`

    

    :weak, :moderate, or :strong

??? info "Source Location"
    `lib/sqa/market_regime.rb:211`

---

### `.split_by_regime(stock)`

Split data by regime

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `stock` | `SQA::Stock` | Stock to analyze |
!!! success "Returns"

    **Type:** `Hash`

    

    Data grouped by regime type

??? info "Source Location"
    `lib/sqa/market_regime.rb:220`

---

## 📝 Attributes

