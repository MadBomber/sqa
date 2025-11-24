# 📦 SQA::Ticker

!!! note "Description"
    sqa/lib/sqa/ticker.rb
    
    Stock ticker symbol validation and lookup using the dumbstockapi.com service.
    Downloads and caches a CSV file containing ticker symbols, company names, and exchanges.

!!! abstract "Source Information"
    **Defined in:** `lib/sqa/ticker.rb:15`
    
    **Inherits from:** `Object`

## 🏭 Class Methods

### `.download(country = "US")`

Downloads ticker data from dumbstockapi.com and saves to data directory.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `country` | `String` | Country code for ticker list (default: "US") |
!!! success "Returns"

    **Type:** `Integer`

    

    HTTP status code from the download request
!!! example "Usage Examples"

    ```ruby
    SQA::Ticker.download("US")  # => 200
    ```
??? info "Source Location"
    `lib/sqa/ticker.rb:31`

---

### `.load()`

Loads ticker data from cached CSV or downloads if not available.
Retries download up to 3 times if no cached file exists.


!!! success "Returns"

    **Type:** `Hash{String => Hash}`

    

    Hash mapping ticker symbols to info hashes

??? info "Source Location"
    `lib/sqa/ticker.rb:47`

---

### `.load_from_csv(csv_path)`

Loads ticker data from a specific CSV file.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `csv_path` | `Pathname, String` | Path to CSV file |
!!! success "Returns"

    **Type:** `Hash{String => Hash}`

    

    Hash mapping ticker symbols to info hashes

??? info "Source Location"
    `lib/sqa/ticker.rb:77`

---

### `.data()`

Returns the cached ticker data, loading it if necessary.


!!! success "Returns"

    **Type:** `Hash{String => Hash}`

    

    Hash mapping ticker symbols to info hashes

??? info "Source Location"
    `lib/sqa/ticker.rb:92`

---

### `.lookup(ticker)`

Looks up information for a specific ticker symbol.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `ticker` | `String, nil` | Ticker symbol to look up |
!!! success "Returns"

    **Type:** `Hash, nil`

    

    Hash with :name and :exchange keys, or nil if not found
!!! example "Usage Examples"

    ```ruby
    SQA::Ticker.lookup('AAPL')  # => { name: "Apple Inc", exchange: "NASDAQ" }
    SQA::Ticker.lookup('FAKE')  # => nil
    ```
??? info "Source Location"
    `lib/sqa/ticker.rb:106`

---

### `.valid?(ticker)`

Checks if a ticker symbol is valid (exists in the data).

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `ticker` | `String, nil` | Ticker symbol to validate |
!!! success "Returns"

    **Type:** `Boolean`

    

    true if ticker exists, false otherwise
!!! example "Usage Examples"

    ```ruby
    SQA::Ticker.valid?('AAPL')  # => true
    SQA::Ticker.valid?(nil)     # => false
    ```
??? info "Source Location"
    `lib/sqa/ticker.rb:120`

---

### `.reset!()`

Resets the cached ticker data.
Useful for testing to force a fresh load.


!!! success "Returns"

    **Type:** `Hash`

    

    Empty hash

??? info "Source Location"
    `lib/sqa/ticker.rb:129`

---

## 📝 Attributes

