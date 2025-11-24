# 📦 SQA::DataFrame::Data

!!! note "Description"
    Data class to store stock metadata
    
    This class holds metadata about a stock including its ticker symbol,
    name, exchange, data source, technical indicators, and company overview.

!!! abstract "Source Information"
    **Defined in:** `lib/sqa/data_frame/data.rb:23`
    
    **Inherits from:** `Object`

## 🔨 Instance Methods

### `#ticker()`


!!! success "Returns"

    **Type:** `String, nil`

    

    Stock ticker symbol (e.g., 'AAPL', 'MSFT')

??? info "Source Location"
    `lib/sqa/data_frame/data.rb:36`

---

### `#ticker=(value)`


!!! success "Returns"

    **Type:** `String, nil`

    

    Stock ticker symbol (e.g., 'AAPL', 'MSFT')

??? info "Source Location"
    `lib/sqa/data_frame/data.rb:36`

---

### `#name()`


!!! success "Returns"

    **Type:** `String, nil`

    

    Company name

??? info "Source Location"
    `lib/sqa/data_frame/data.rb:36`

---

### `#name=(value)`


!!! success "Returns"

    **Type:** `String, nil`

    

    Company name

??? info "Source Location"
    `lib/sqa/data_frame/data.rb:36`

---

### `#exchange()`


!!! success "Returns"

    **Type:** `String, nil`

    

    Exchange where stock trades (e.g., 'NASDAQ', 'NYSE')

??? info "Source Location"
    `lib/sqa/data_frame/data.rb:36`

---

### `#exchange=(value)`


!!! success "Returns"

    **Type:** `String, nil`

    

    Exchange where stock trades (e.g., 'NASDAQ', 'NYSE')

??? info "Source Location"
    `lib/sqa/data_frame/data.rb:36`

---

### `#source()`


!!! success "Returns"

    **Type:** `Symbol`

    

    Data source (:alpha_vantage, :yahoo_finance)

??? info "Source Location"
    `lib/sqa/data_frame/data.rb:36`

---

### `#source=(value)`


!!! success "Returns"

    **Type:** `Symbol`

    

    Data source (:alpha_vantage, :yahoo_finance)

??? info "Source Location"
    `lib/sqa/data_frame/data.rb:36`

---

### `#indicators()`


!!! success "Returns"

    **Type:** `Hash`

    

    Technical indicators configuration and cached values

??? info "Source Location"
    `lib/sqa/data_frame/data.rb:36`

---

### `#indicators=(value)`


!!! success "Returns"

    **Type:** `Hash`

    

    Technical indicators configuration and cached values

??? info "Source Location"
    `lib/sqa/data_frame/data.rb:36`

---

### `#overview()`


!!! success "Returns"

    **Type:** `Hash`

    

    Company overview data from API

??? info "Source Location"
    `lib/sqa/data_frame/data.rb:36`

---

### `#overview=(value)`

Sets the attribute overview

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute overview to. |


??? info "Source Location"
    `lib/sqa/data_frame/data.rb:36`

---

### `#initialize(data_hash = nil, ticker: = nil, name: = nil, exchange: = nil, source: = :alpha_vantage, indicators: = {}, overview: = {})`

Initializes stock metadata.

Can be called in two ways:
  1. With a hash: SQA::DataFrame::Data.new(hash) - for JSON deserialization
  2. With keyword args: SQA::DataFrame::Data.new(ticker: 'AAPL', source: :alpha_vantage, ...)

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `data_hash` | `Hash, nil` | Hash of all attributes (when passed as first positional arg) |
    | `ticker` | `String, Symbol, nil` | Ticker symbol |
    | `name` | `String, nil` | Stock name |
    | `exchange` | `String, nil` | Exchange symbol (e.g., 'NASDAQ', 'NYSE') |
    | `source` | `Symbol` | Data source (:alpha_vantage, :yahoo_finance) |
    | `indicators` | `Hash` | Technical indicators configuration |
    | `overview` | `Hash` | Company overview data |
!!! success "Returns"

    **Type:** `Data`

    

    a new instance of Data

??? info "Source Location"
    `lib/sqa/data_frame/data.rb:52`

---

### `#to_json(*args)`

Serialize to JSON string


!!! success "Returns"

    **Type:** `String`

    

    JSON representation

??? info "Source Location"
    `lib/sqa/data_frame/data.rb:78`

---

### `#to_h()`

Convert to hash


!!! success "Returns"

    **Type:** `Hash`

    

    Hash representation

??? info "Source Location"
    `lib/sqa/data_frame/data.rb:85`

---

### `#to_s()`

String representation


!!! success "Returns"

    **Type:** `String`

    

    Human-readable representation

??? info "Source Location"
    `lib/sqa/data_frame/data.rb:99`

---

### `#inspect()`

String representation


!!! success "Returns"

    **Type:** `String`

    

    Human-readable representation

??? info "Source Location"
    `lib/sqa/data_frame/data.rb:102`

---

## 📝 Attributes

### 🔄 `ticker` <small>read/write</small>

### 🔄 `name` <small>read/write</small>

### 🔄 `exchange` <small>read/write</small>

### 🔄 `source` <small>read/write</small>

### 🔄 `indicators` <small>read/write</small>

### 🔄 `overview` <small>read/write</small>

