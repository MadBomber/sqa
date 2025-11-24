# 📦 SQA::DataFrame

!!! note "Description"
    High-performance DataFrame wrapper around Polars for time series data manipulation.
    Provides convenience methods for stock market data while leveraging Polars' Rust-backed
    performance for vectorized operations.

!!! abstract "Source Information"
    **Defined in:** [`lib/sqa/data_frame.rb:28`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L28)
    
    **Inherits from:** `Object`

## 🏭 Class Methods

### `.is_date?(value)`

Checks if a value appears to be a date string.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Object` | Value to check |
!!! success "Returns"

    **Type:** `Boolean`

    

    true if value matches YYYY-MM-DD format

??? info "Source Location"
    [`lib/sqa/data_frame.rb:246`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L246)

---

### `.load(source:, transformers: = {}, mapping: = {})`

Load a DataFrame from a file source
This is the primary method for loading persisted DataFrames

Note: For cached CSV files, transformers and mapping should typically be empty
since transformations were already applied when the data was first fetched.
We only apply them if the CSV has old-format column names that need migration.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `source` | `String, Pathname` | Path to CSV file |
    | `transformers` | `Hash` | Column transformations to apply (usually not needed for cached data) |
    | `mapping` | `Hash` | Column name mappings (usually not needed for cached data) |
!!! success "Returns"

    **Type:** `SQA::DataFrame`

    

    Loaded DataFrame

??? info "Source Location"
    [`lib/sqa/data_frame.rb:283`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L283)

---

### `.from_aofh(aofh, mapping: = {}, transformers: = {})`

Creates a DataFrame from an array of hashes.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `aofh` | `Array<Hash>` | Array of hash records |
    | `mapping` | `Hash` | Column name mappings to apply |
    | `transformers` | `Hash` | Column transformers to apply |
!!! success "Returns"

    **Type:** `SQA::DataFrame`

    

    New DataFrame instance
!!! example "Usage Examples"

    ```ruby
    data = [{ "date" => "2024-01-01", "price" => 100.0 }]
    df = SQA::DataFrame.from_aofh(data)
    ```
??? info "Source Location"
    [`lib/sqa/data_frame.rb:302`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L302)

---

### `.from_csv_file(source, mapping: = {}, transformers: = {})`

Creates a DataFrame from a CSV file.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `source` | `String, Pathname` | Path to CSV file |
    | `mapping` | `Hash` | Column name mappings to apply |
    | `transformers` | `Hash` | Column transformers to apply |
!!! success "Returns"

    **Type:** `SQA::DataFrame`

    

    New DataFrame instance

??? info "Source Location"
    [`lib/sqa/data_frame.rb:324`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L324)

---

### `.from_json_file(source, mapping: = {}, transformers: = {})`

Creates a DataFrame from a JSON file.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `source` | `String, Pathname` | Path to JSON file containing array of objects |
    | `mapping` | `Hash` | Column name mappings to apply |
    | `transformers` | `Hash` | Column transformers to apply |
!!! success "Returns"

    **Type:** `SQA::DataFrame`

    

    New DataFrame instance

??? info "Source Location"
    [`lib/sqa/data_frame.rb:335`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L335)

---

### `.generate_mapping(keys)`

Generates a mapping of original keys to underscored keys.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `keys` | `Array<String>` | Original key names |
!!! success "Returns"

    **Type:** `Hash{String => Symbol}`

    

    Mapping from original to underscored keys

??? info "Source Location"
    [`lib/sqa/data_frame.rb:344`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L344)

---

### `.underscore_key(key)`

Converts a key string to underscored snake_case format.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `key` | `String` | Key to convert |
!!! success "Returns"

    **Type:** `Symbol`

    

    Underscored key as symbol
!!! example "Usage Examples"

    ```ruby
    underscore_key("closePrice")  # => :close_price
    underscore_key("Close Price") # => :close_price
    ```
??? info "Source Location"
    [`lib/sqa/data_frame.rb:359`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L359)

---

### `.sanitize_key()`

Converts a key string to underscored snake_case format.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `key` | `String` | Key to convert |
!!! success "Returns"

    **Type:** `Symbol`

    

    Underscored key as symbol
!!! example "Usage Examples"

    ```ruby
    underscore_key("closePrice")  # => :close_price
    underscore_key("Close Price") # => :close_price
    ```
??? info "Source Location"
    [`lib/sqa/data_frame.rb:371`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L371)

---

### `.normalize_keys(hash, adapter_mapping: = {})`

Normalizes all keys in a hash to snake_case format.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `hash` | `Hash` | Hash with keys to normalize |
    | `adapter_mapping` | `Hash` | Optional pre-mapping to apply first |
!!! success "Returns"

    **Type:** `Hash`

    

    Hash with normalized keys

??? info "Source Location"
    [`lib/sqa/data_frame.rb:378`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L378)

---

### `.rename(hash, mapping)`

Renames keys in a hash according to a mapping.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `hash` | `Hash` | Hash to modify |
    | `mapping` | `Hash` | Old key to new key mapping |
!!! success "Returns"

    **Type:** `Hash`

    

    Modified hash

??? info "Source Location"
    [`lib/sqa/data_frame.rb:389`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L389)

---

### `.aofh_to_hofa(aofh, mapping: = {}, transformers: = {})`

Converts array of hashes to hash of arrays format.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `aofh` | `Array<Hash>` | Array of hash records |
    | `mapping` | `Hash` | Column name mappings (unused, for API compatibility) |
    | `transformers` | `Hash` | Column transformers (unused, for API compatibility) |
!!! success "Returns"

    **Type:** `Hash{String => Array}`

    

    Hash with column names as keys and arrays as values

??? info "Source Location"
    [`lib/sqa/data_frame.rb:400`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L400)

---

## 🔨 Instance Methods

### `#data()`


!!! success "Returns"

    **Type:** `Polars::DataFrame`

    

    The underlying Polars DataFrame

??? info "Source Location"
    [`lib/sqa/data_frame.rb:33`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L33)

---

### `#data=(value)`

Sets the attribute data

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute data to. |


??? info "Source Location"
    [`lib/sqa/data_frame.rb:33`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L33)

---

### `#initialize(raw_data = nil, mapping: = {}, transformers: = {})`

Creates a new DataFrame instance.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `raw_data` | `Hash, Array, Polars::DataFrame, nil` | Initial data for the DataFrame |
    | `mapping` | `Hash` | Column name mappings to apply (old_name => new_name) |
    | `transformers` | `Hash` | Column transformers to apply (column => lambda) |
!!! success "Returns"

    **Type:** `DataFrame`

    

    a new instance of DataFrame
!!! example "Usage Examples"

    ```ruby
    df = SQA::DataFrame.new(data, mapping: { "Close" => "close_price" })
    ```
    
    ```ruby
    df = SQA::DataFrame.new(data, transformers: { "price" => ->(v) { v.to_f } })
    ```
??? info "Source Location"
    [`lib/sqa/data_frame.rb:47`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L47)

---

### `#apply_transformers!(transformers)`

Applies transformer functions to specified columns in place.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `transformers` | `Hash{String, Symbol => Proc}` | Column name to transformer mapping |
!!! success "Returns"

    **Type:** `void`

    
!!! example "Usage Examples"

    ```ruby
    df.apply_transformers!({ "price" => ->(v) { v.to_f }, "volume" => ->(v) { v.to_i } })
    ```
??? info "Source Location"
    [`lib/sqa/data_frame.rb:65`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L65)

---

### `#rename_columns!(mapping)`

Renames columns according to the provided mapping in place.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `mapping` | `Hash{String, Symbol => String}` | Old column name to new column name mapping |
!!! success "Returns"

    **Type:** `void`

    
!!! example "Usage Examples"

    ```ruby
    df.rename_columns!({ "open" => "open_price", "close" => "close_price" })
    ```
??? info "Source Location"
    [`lib/sqa/data_frame.rb:82`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L82)

---

### `#append!(other_df)`

Appends another DataFrame to this one in place.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `other_df` | `SQA::DataFrame` | DataFrame to append |
!!! success "Returns"

    **Type:** `void`

    
!!! example "Usage Examples"

    ```ruby
    df1.append!(df2)
    ```
??? info "Source Location"
    [`lib/sqa/data_frame.rb:107`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L107)

---

### `#concat!()`

Appends another DataFrame to this one in place.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `other_df` | `SQA::DataFrame` | DataFrame to append |
!!! success "Returns"

    **Type:** `void`

    
!!! example "Usage Examples"

    ```ruby
    df1.append!(df2)
    ```
??? info "Source Location"
    [`lib/sqa/data_frame.rb:124`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L124)

---

### `#concat_and_deduplicate!(other_df, sort_column: = "timestamp", descending: = false)`

Concatenate another DataFrame, remove duplicates, and sort
This is the preferred method for updating CSV data to prevent duplicates

NOTE: TA-Lib requires data in ascending (oldest-first) order. Using descending: true
will produce a warning and force ascending order to prevent silent calculation errors.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `other_df` | `SQA::DataFrame` | DataFrame to append |
    | `sort_column` | `String` | Column to use for deduplication and sorting (default: "timestamp") |
    | `descending` | `Boolean` | Sort order - false for ascending (oldest first, TA-Lib compatible), true for descending |

!!! example "Usage Examples"

    ```ruby
    stock = SQA::Stock.new(ticker: 'AAPL')
    df = stock.df
    df.size  # => 252
    
    # Fetch recent data (may have overlapping dates)
    new_df = SQA::DataFrame::AlphaVantage.recent('AAPL', from_date: Date.today - 7)
    df.concat_and_deduplicate!(new_df)
    # Duplicates removed, data sorted ascending (oldest first)
    df.size  # => 255 (only 3 new unique dates added)
    ```
    
    ```ruby
    df.concat_and_deduplicate!(new_df)  # Sorted ascending automatically
    prices = df["adj_close_price"].to_a
    rsi = SQAI.rsi(prices, period: 14)  # Works correctly with ascending data
    ```
??? info "Source Location"
    [`lib/sqa/data_frame.rb:135`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L135)

---

### `#columns()`

Returns the column names of the DataFrame.


!!! success "Returns"

    **Type:** `Array<String>`

    

    List of column names

??? info "Source Location"
    [`lib/sqa/data_frame.rb:159`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L159)

---

### `#keys()`

Returns the column names of the DataFrame.
Alias for {#columns}.


!!! success "Returns"

    **Type:** `Array<String>`

    

    List of column names

??? info "Source Location"
    [`lib/sqa/data_frame.rb:167`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L167)

---

### `#vectors()`

Returns the column names of the DataFrame.
Alias for {#columns}.


!!! success "Returns"

    **Type:** `Array<String>`

    

    List of column names

??? info "Source Location"
    [`lib/sqa/data_frame.rb:170`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L170)

---

### `#to_h()`

Converts the DataFrame to a Ruby Hash.


!!! success "Returns"

    **Type:** `Hash{Symbol => Array}`

    

    Hash with column names as keys and column data as arrays
!!! example "Usage Examples"

    ```ruby
    df.to_h  # => { timestamp: ["2024-01-01", ...], close_price: [100.0, ...] }
    ```
??? info "Source Location"
    [`lib/sqa/data_frame.rb:179`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L179)

---

### `#to_csv(path_to_file)`

Writes the DataFrame to a CSV file.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `path_to_file` | `String, Pathname` | Path to output CSV file |
!!! success "Returns"

    **Type:** `void`

    
!!! example "Usage Examples"

    ```ruby
    stock = SQA::Stock.new(ticker: 'AAPL')
    stock.df.to_csv('aapl_prices.csv')
    ```
    
    ```ruby
    df.to_csv(Pathname.new('data/exports/prices.csv'))
    ```
??? info "Source Location"
    [`lib/sqa/data_frame.rb:187`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L187)

---

### `#size()`

Returns the number of rows in the DataFrame.


!!! success "Returns"

    **Type:** `Integer`

    

    Row count

??? info "Source Location"
    [`lib/sqa/data_frame.rb:194`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L194)

---

### `#nrows()`

Returns the number of rows in the DataFrame.


!!! success "Returns"

    **Type:** `Integer`

    

    Row count

??? info "Source Location"
    [`lib/sqa/data_frame.rb:197`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L197)

---

### `#length()`

Returns the number of rows in the DataFrame.


!!! success "Returns"

    **Type:** `Integer`

    

    Row count

??? info "Source Location"
    [`lib/sqa/data_frame.rb:198`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L198)

---

### `#ncols()`

Returns the number of columns in the DataFrame.


!!! success "Returns"

    **Type:** `Integer`

    

    Column count

??? info "Source Location"
    [`lib/sqa/data_frame.rb:203`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L203)

---

### `#fpl(column: = 'adj_close_price', fpop: = 14)`

FPL Analysis - Calculate Future Period Loss/Profit

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `column` | `String, Symbol` | Column name containing prices (default: "adj_close_price") |
    | `fpop` | `Integer` | Future Period of Performance (days to look ahead) |
!!! success "Returns"

    **Type:** `Array<Array<Float, Float>>`

    

    Array of [min_delta, max_delta] pairs
!!! example "Usage Examples"

    ```ruby
    stock = SQA::Stock.new(ticker: 'AAPL')
    fpl_data = stock.df.fpl(fpop: 10)
    ```
??? info "Source Location"
    [`lib/sqa/data_frame.rb:218`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L218)

---

### `#fpl_analysis(column: = 'adj_close_price', fpop: = 14)`

FPL Analysis with risk metrics and classification

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `column` | `String, Symbol` | Column name containing prices (default: "adj_close_price") |
    | `fpop` | `Integer` | Future Period of Performance |
!!! success "Returns"

    **Type:** `Array<Hash>`

    

    Array of analysis hashes
!!! example "Usage Examples"

    ```ruby
    analysis = stock.df.fpl_analysis(fpop: 10)
    analysis.first[:direction]  # => :UP, :DOWN, :UNCERTAIN, or :FLAT
    analysis.first[:magnitude]  # => Average expected movement percentage
    analysis.first[:risk]       # => Volatility range
    ```
??? info "Source Location"
    [`lib/sqa/data_frame.rb:236`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L236)

---

### `#method_missing(method_name, *args, &block)`

Delegates unknown methods to the underlying Polars DataFrame.
This allows direct access to Polars methods like filter, select, etc.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `method_name` | `Symbol` | Method name being called |
    | `args` | `Array` | Method arguments |
    | `block` | `Proc` | Optional block |
!!! success "Returns"

    **Type:** `Object`

    

    Result from Polars DataFrame method

??? info "Source Location"
    [`lib/sqa/data_frame.rb:257`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L257)

---

### `#respond_to_missing?(method_name, include_private = false)`

Checks if the DataFrame responds to a method.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `method_name` | `Symbol` | Method name to check |
    | `include_private` | `Boolean` | Include private methods |
!!! success "Returns"

    **Type:** `Boolean`

    

    true if method is available

??? info "Source Location"
    [`lib/sqa/data_frame.rb:267`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame.rb#L267)

---

## 📝 Attributes

### 🔄 `data` <small>read/write</small>

