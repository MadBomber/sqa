# 🔧 SQA

!!! note "Description"
    Knowledge-Based Strategy using RETE Forward Chaining
    
    This strategy uses a rule-based system with the RETE algorithm for
    forward-chaining inference. It allows defining complex trading rules
    that react to market conditions.
    
    The strategy asserts facts about market conditions (RSI, trends, volume, etc.)
    and fires rules when patterns are matched.
    
    DSL Keywords:
      - on        : Assert a condition (fact must exist)
      - without   : Negated condition (fact must NOT exist)
      - perform   : Define action to execute when rule fires
      - execute   : Alias for perform
      - action    : Alias for perform
    
    Example:
      strategy = SQA::Strategy::KBS.new
    
      # Capture kb for use in perform blocks
      kb = strategy.kb
    
      # Define custom rules using the DSL
      strategy.add_rule :buy_oversold_uptrend do
        on :rsi, { level: :oversold }
        on :trend, { direction: :up }
        without :position
    
        perform do
          kb.assert(:signal, { action: :buy, confidence: :high })
        end
      end
    
      # Execute strategy
      signal = strategy.trade(vector)
    
    Note: Use 'kb.assert' (not just 'assert') in perform blocks to access the knowledge base.

!!! abstract "Source Information"
    **Defined in:** [`lib/sqa/gp.rb:34`](https://github.com/madbomber/sqa/blob/main/lib/sqa/gp.rb#L34)

## 🏭 Class Methods

### `.config=(value)`

Sets the attribute config

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute config to. |


??? info "Source Location"
    [`lib/sqa/init.rb:22`](https://github.com/madbomber/sqa/blob/main/lib/sqa/init.rb#L22)

---

### `.init(argv = ARGV)`

Initializes the SQA library.
Should be called once at application startup.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `argv` | `Array<String>, String` | Command line arguments (default: ARGV) |
!!! success "Returns"

    **Type:** `SQA::Config`

    

    The configuration instance
!!! example "Usage Examples"

    ```ruby
    SQA.init
    SQA.init("--debug --verbose")
    ```
??? info "Source Location"
    [`lib/sqa/init.rb:34`](https://github.com/madbomber/sqa/blob/main/lib/sqa/init.rb#L34)

---

### `.av_api_key()`

Returns the Alpha Vantage API key.
Reads from AV_API_KEY or ALPHAVANTAGE_API_KEY environment variables.


!!! success "Returns"

    **Type:** `String`

    

    The API key

??? info "Source Location"
    [`lib/sqa/init.rb:61`](https://github.com/madbomber/sqa/blob/main/lib/sqa/init.rb#L61)

---

### `.av_api_key=(key)`

Sets the Alpha Vantage API key.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `key` | `String` | The API key to set |
!!! success "Returns"

    **Type:** `String`

    

    The key that was set

??? info "Source Location"
    [`lib/sqa/init.rb:70`](https://github.com/madbomber/sqa/blob/main/lib/sqa/init.rb#L70)

---

### `.av()`

Legacy accessor for backward compatibility with SQA.av.key usage.


!!! success "Returns"

    **Type:** `SQA`

    

    Self, to allow SQA.av.key calls

??? info "Source Location"
    [`lib/sqa/init.rb:77`](https://github.com/madbomber/sqa/blob/main/lib/sqa/init.rb#L77)

---

### `.key()`

Returns the API key for compatibility with old SQA.av.key usage.


!!! success "Returns"

    **Type:** `String`

    

    The API key

??? info "Source Location"
    [`lib/sqa/init.rb:85`](https://github.com/madbomber/sqa/blob/main/lib/sqa/init.rb#L85)

---

### `.debug?()`

Returns whether debug mode is enabled.


!!! success "Returns"

    **Type:** `Boolean`

    

    true if debug mode is on

??? info "Source Location"
    [`lib/sqa/init.rb:91`](https://github.com/madbomber/sqa/blob/main/lib/sqa/init.rb#L91)

---

### `.verbose?()`

Returns whether verbose mode is enabled.


!!! success "Returns"

    **Type:** `Boolean`

    

    true if verbose mode is on

??? info "Source Location"
    [`lib/sqa/init.rb:95`](https://github.com/madbomber/sqa/blob/main/lib/sqa/init.rb#L95)

---

### `.homify(filepath)`

Expands ~ to user's home directory in filepath.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `filepath` | `String` | Path potentially containing ~ |
!!! success "Returns"

    **Type:** `String`

    

    Path with ~ expanded

??? info "Source Location"
    [`lib/sqa/init.rb:101`](https://github.com/madbomber/sqa/blob/main/lib/sqa/init.rb#L101)

---

### `.data_dir()`

Returns the data directory as a Pathname.


!!! success "Returns"

    **Type:** `Pathname`

    

    Data directory path

??? info "Source Location"
    [`lib/sqa/init.rb:106`](https://github.com/madbomber/sqa/blob/main/lib/sqa/init.rb#L106)

---

### `.config()`

Returns the current configuration.


!!! success "Returns"

    **Type:** `SQA::Config`

    

    Configuration instance

??? info "Source Location"
    [`lib/sqa/init.rb:111`](https://github.com/madbomber/sqa/blob/main/lib/sqa/init.rb#L111)

---

## 📝 Attributes

### 🔄 `config` <small>read/write</small>

Returns the current configuration.

