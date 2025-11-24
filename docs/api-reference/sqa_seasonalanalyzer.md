# 🔧 SQA::SeasonalAnalyzer

!!! abstract "Source Information"
    **Defined in:** `lib/sqa/seasonal_analyzer.rb:18`

## 🏭 Class Methods

### `.analyze(stock)`

Analyze seasonal performance patterns

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `stock` | `SQA::Stock` | Stock to analyze |
!!! success "Returns"

    **Type:** `Hash`

    

    Seasonal performance metadata

??? info "Source Location"
    `lib/sqa/seasonal_analyzer.rb:25`

---

### `.filter_by_months(stock, months)`

Filter data by calendar months

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `stock` | `SQA::Stock` | Stock to analyze |
    | `months` | `Array<Integer>` | Months to include (1-12) |
!!! success "Returns"

    **Type:** `Hash`

    

    Filtered data

??? info "Source Location"
    `lib/sqa/seasonal_analyzer.rb:56`

---

### `.filter_by_quarters(stock, quarters)`

Filter data by quarters

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `stock` | `SQA::Stock` | Stock to analyze |
    | `quarters` | `Array<Integer>` | Quarters to include (1-4) |
!!! success "Returns"

    **Type:** `Hash`

    

    Filtered data

??? info "Source Location"
    `lib/sqa/seasonal_analyzer.rb:82`

---

### `.detect_seasonality(monthly_returns)`

Detect if stock has seasonal pattern

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `monthly_returns` | `Hash` | Monthly return statistics |
!!! success "Returns"

    **Type:** `Boolean`

    

    True if significant seasonal pattern exists

??? info "Source Location"
    `lib/sqa/seasonal_analyzer.rb:99`

---

### `.context_for_date(date)`

Get seasonal context for a specific date

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `date` | `Date` | Date to check |
!!! success "Returns"

    **Type:** `Hash`

    

    Seasonal context

??? info "Source Location"
    `lib/sqa/seasonal_analyzer.rb:116`

---

## 📝 Attributes

