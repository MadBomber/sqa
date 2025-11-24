# 📦 SQA::Stock

!!! note "Description"
    Represents a stock with price history, metadata, and technical analysis capabilities.
    This is the primary domain object for interacting with stock data.

!!! abstract "Source Information"
    **Defined in:** [`lib/sqa/stock.rb:14`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L14)
    
    **Inherits from:** `Object`

## 🏭 Class Methods

### `.connection()`

Returns the current Faraday connection for API requests.
Allows injection of custom connections for testing or different configurations.


!!! success "Returns"

    **Type:** `Faraday::Connection`

    

    The current connection instance

??? info "Source Location"
    [`lib/sqa/stock.rb:30`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L30)

---

### `.connection=(conn)`

Sets a custom Faraday connection.
Useful for testing with mocks/stubs or configuring different API endpoints.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `conn` | `Faraday::Connection` | Custom Faraday connection to use |
!!! success "Returns"

    **Type:** `Faraday::Connection`

    

    The connection that was set

??? info "Source Location"
    [`lib/sqa/stock.rb:39`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L39)

---

### `.default_connection()`

Creates the default Faraday connection to Alpha Vantage.


!!! success "Returns"

    **Type:** `Faraday::Connection`

    

    A new connection to Alpha Vantage API

??? info "Source Location"
    [`lib/sqa/stock.rb:46`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L46)

---

### `.reset_connection!()`

Resets the connection to default.
Useful for testing cleanup to ensure fresh state between tests.


!!! success "Returns"

    **Type:** `nil`

    

??? info "Source Location"
    [`lib/sqa/stock.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L54)

---

### `.top()`

Fetches top gainers, losers, and most actively traded stocks from Alpha Vantage.
Results are cached after the first call.


!!! success "Returns"

    **Type:** `Hashie::Mash`

    

    Object with top_gainers, top_losers, and most_actively_traded arrays
!!! example "Usage Examples"

    ```ruby
    top = SQA::Stock.top
    top.top_gainers.each { |stock| puts "#{stock.ticker}: +#{stock.change_percentage}%" }
    top.top_losers.first.ticker  # => "XYZ"
    ```
??? info "Source Location"
    [`lib/sqa/stock.rb:341`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L341)

---

### `.reset_top!()`

Resets the cached top gainers/losers data.
Useful for testing or forcing a refresh.


!!! success "Returns"

    **Type:** `nil`

    

??? info "Source Location"
    [`lib/sqa/stock.rb:372`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L372)

---

## 🔨 Instance Methods

### `#data()`


!!! success "Returns"

    **Type:** `SQA::DataFrame::Data`

    

    Stock metadata (ticker, name, exchange, etc.)

??? info "Source Location"
    [`lib/sqa/stock.rb:69`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L69)

---

### `#data=(value)`


!!! success "Returns"

    **Type:** `SQA::DataFrame::Data`

    

    Stock metadata (ticker, name, exchange, etc.)

??? info "Source Location"
    [`lib/sqa/stock.rb:69`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L69)

---

### `#df()`


!!! success "Returns"

    **Type:** `SQA::DataFrame`

    

    Price and volume data as a DataFrame

??? info "Source Location"
    [`lib/sqa/stock.rb:69`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L69)

---

### `#df=(value)`


!!! success "Returns"

    **Type:** `SQA::DataFrame`

    

    Price and volume data as a DataFrame

??? info "Source Location"
    [`lib/sqa/stock.rb:69`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L69)

---

### `#klass()`


!!! success "Returns"

    **Type:** `Class`

    

    The data source class (e.g., SQA::DataFrame::AlphaVantage)

??? info "Source Location"
    [`lib/sqa/stock.rb:69`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L69)

---

### `#klass=(value)`


!!! success "Returns"

    **Type:** `Class`

    

    The data source class (e.g., SQA::DataFrame::AlphaVantage)

??? info "Source Location"
    [`lib/sqa/stock.rb:69`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L69)

---

### `#transformers()`


!!! success "Returns"

    **Type:** `Hash`

    

    Column transformers for data normalization

??? info "Source Location"
    [`lib/sqa/stock.rb:69`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L69)

---

### `#transformers=(value)`


!!! success "Returns"

    **Type:** `Hash`

    

    Column transformers for data normalization

??? info "Source Location"
    [`lib/sqa/stock.rb:69`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L69)

---

### `#strategy()`


!!! success "Returns"

    **Type:** `SQA::Strategy, nil`

    

    Optional trading strategy attached to this stock

??? info "Source Location"
    [`lib/sqa/stock.rb:69`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L69)

---

### `#strategy=(value)`

Sets the attribute strategy

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute strategy to. |


??? info "Source Location"
    [`lib/sqa/stock.rb:69`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L69)

---

### `#initialize(ticker:, source: = :alpha_vantage)`

Creates a new Stock instance and loads or fetches its data.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `ticker` | `String` | The stock ticker symbol (e.g., 'AAPL', 'MSFT') |
    | `source` | `Symbol` | The data source to use (:alpha_vantage or :yahoo_finance) |
!!! success "Returns"

    **Type:** `Stock`

    

    a new instance of Stock
!!! example "Usage Examples"

    ```ruby
    stock = SQA::Stock.new(ticker: 'AAPL')
    stock = SQA::Stock.new(ticker: 'GOOG', source: :yahoo_finance)
    ```
??? info "Source Location"
    [`lib/sqa/stock.rb:81`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L81)

---

### `#load_or_create_data()`

Loads existing data from cache or creates new data structure.
If cached data exists, loads from JSON file. Otherwise creates
minimal structure and attempts to fetch overview from API.


!!! success "Returns"

    **Type:** `void`

    

??? info "Source Location"
    [`lib/sqa/stock.rb:107`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L107)

---

### `#create_data()`

Creates a new minimal data structure for the stock.


!!! success "Returns"

    **Type:** `SQA::DataFrame::Data`

    

    The newly created data object

??? info "Source Location"
    [`lib/sqa/stock.rb:126`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L126)

---

### `#update()`

Updates the stock's overview data from the API.
Silently handles errors since overview data is optional.


!!! success "Returns"

    **Type:** `void`

    
!!! example "Usage Examples"

    ```ruby
    stock = SQA::Stock.new(ticker: 'AAPL')
    stock.update  # Fetches latest company overview data
    stock.data.overview['market_capitalization']  # => 2500000000000
    stock.data.overview['pe_ratio']  # => 28.5
    ```
    
    ```ruby
    stock.update  # No error raised if API is unavailable
    # Warning logged but stock remains usable with cached data
    ```
??? info "Source Location"
    [`lib/sqa/stock.rb:134`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L134)

---

### `#save_data()`

Persists the stock's metadata to a JSON file.


!!! success "Returns"

    **Type:** `Integer`

    

    Number of bytes written

??? info "Source Location"
    [`lib/sqa/stock.rb:147`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L147)

---

### `#ticker()`


!!! success "Returns"

    **Type:** `String`

    

    The stock's ticker symbol

??? info "Source Location"
    [`lib/sqa/stock.rb:165`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L165)

---

### `#name()`


!!! success "Returns"

    **Type:** `String, nil`

    

    The company name

??? info "Source Location"
    [`lib/sqa/stock.rb:165`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L165)

---

### `#exchange()`


!!! success "Returns"

    **Type:** `String, nil`

    

    The exchange where the stock trades

??? info "Source Location"
    [`lib/sqa/stock.rb:165`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L165)

---

### `#source()`


!!! success "Returns"

    **Type:** `Symbol`

    

    The data source (:alpha_vantage or :yahoo_finance)

??? info "Source Location"
    [`lib/sqa/stock.rb:165`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L165)

---

### `#indicators()`


!!! success "Returns"

    **Type:** `Hash`

    

    Cached indicator values

??? info "Source Location"
    [`lib/sqa/stock.rb:165`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L165)

---

### `#indicators=(value)`

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Hash` | New indicator values |


??? info "Source Location"
    [`lib/sqa/stock.rb:165`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L165)

---

### `#overview()`


!!! success "Returns"

    **Type:** `Hash, nil`

    

    Company overview data from API

??? info "Source Location"
    [`lib/sqa/stock.rb:165`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L165)

---

### `#update_dataframe()`

Updates the DataFrame with price data.
Loads from cache if available, otherwise fetches from API.
Applies migrations for old data formats and updates with recent data.


!!! success "Returns"

    **Type:** `void`

    

??? info "Source Location"
    [`lib/sqa/stock.rb:173`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L173)

---

### `#update_dataframe_with_recent_data()`

Fetches recent data from API and appends to existing DataFrame.
Only called if should_update? returns true.


!!! success "Returns"

    **Type:** `void`

    

??? info "Source Location"
    [`lib/sqa/stock.rb:228`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L228)

---

### `#update_the_dataframe()`


!!! success "Returns"

    **Type:** `void`

    

??? info "Source Location"
    [`lib/sqa/stock.rb:250`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L250)

---

### `#should_update?()`

Determines whether the DataFrame should be updated from the API.
Returns false if lazy_update is enabled, API key is missing,
or data is already current.


!!! success "Returns"

    **Type:** `Boolean`

    

    true if update should proceed, false otherwise

??? info "Source Location"
    [`lib/sqa/stock.rb:260`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L260)

---

### `#to_s()`

Returns a human-readable string representation of the stock.


!!! success "Returns"

    **Type:** `String`

    

    Summary including ticker, data points count, and date range
!!! example "Usage Examples"

    ```ruby
    stock.to_s  # => "aapl with 252 data points from 2023-01-03 to 2023-12-29"
    ```
??? info "Source Location"
    [`lib/sqa/stock.rb:294`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L294)

---

### `#inspect()`

Returns a human-readable string representation of the stock.
Note: CSV data is stored in ascending chronological order (oldest to newest)
This ensures compatibility with TA-Lib indicators which expect arrays in this order


!!! success "Returns"

    **Type:** `String`

    

    Summary including ticker, data points count, and date range
!!! example "Usage Examples"

    ```ruby
    stock.to_s  # => "aapl with 252 data points from 2023-01-03 to 2023-12-29"
    ```
??? info "Source Location"
    [`lib/sqa/stock.rb:299`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L299)

---

### `#merge_overview()`

Fetches and merges company overview data from Alpha Vantage API.
Converts API response keys to snake_case and appropriate data types.


!!! success "Returns"

    **Type:** `Hash`

    

    The merged overview data

??? info "Source Location"
    [`lib/sqa/stock.rb:306`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stock.rb#L306)

---

## 📝 Attributes

### 🔄 `data` <small>read/write</small>

### 🔄 `df` <small>read/write</small>

### 🔄 `klass` <small>read/write</small>

### 🔄 `transformers` <small>read/write</small>

### 🔄 `strategy` <small>read/write</small>

