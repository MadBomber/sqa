# 📦 SQA::Strategy

!!! note "Description"
    This module needs to be extend'ed within
    a strategy class so that these common class
    methods are available in every trading strategy.

!!! abstract "Source Information"
    **Defined in:** `lib/sqa/strategy.rb:16`
    
    **Inherits from:** `Object`

## 🔨 Instance Methods

### `#strategies()`


!!! success "Returns"

    **Type:** `Array<Method>`

    

    Collection of strategy trade methods

??? info "Source Location"
    `lib/sqa/strategy.rb:19`

---

### `#strategies=(value)`

Sets the attribute strategies

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute strategies to. |


??? info "Source Location"
    `lib/sqa/strategy.rb:19`

---

### `#initialize()`

Creates a new Strategy instance with an empty strategies collection.


!!! success "Returns"

    **Type:** `Strategy`

    

    a new instance of Strategy

??? info "Source Location"
    `lib/sqa/strategy.rb:22`

---

### `#add(a_strategy)`

Adds a trading strategy to the collection.
Strategies must be either a Class with a .trade method or a Method object.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `a_strategy` | `Class, Method` | Strategy to add |
!!! success "Returns"

    **Type:** `Array<Method>`

    

    Updated strategies collection
!!! example "Usage Examples"

    ```ruby
    strategy.add(SQA::Strategy::RSI)
    ```
    
    ```ruby
    strategy.add(MyModule.method(:custom_trade))
    ```
??? info "Source Location"
    `lib/sqa/strategy.rb:39`

---

### `#execute(v)`

Executes all registered strategies with the given data vector.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `v` | `OpenStruct` | Data vector containing indicator values and prices |
!!! success "Returns"

    **Type:** `Array<Symbol>`

    

    Array of signals (:buy, :sell, or :hold) from each strategy
!!! example "Usage Examples"

    ```ruby
    vector = OpenStruct.new(rsi: 25, prices: prices_array)
    signals = strategy.execute(vector)  # => [:buy, :hold, :sell]
    ```
??? info "Source Location"
    `lib/sqa/strategy.rb:60`

---

### `#auto_load(except: = [:common], only: = [])`

Auto-loads strategy files from the strategy directory.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `except` | `Array<Symbol>` | Strategy names to exclude (default: [:common]) |
    | `only` | `Array<Symbol>` | If provided, only load these strategies |
!!! success "Returns"

    **Type:** `nil`

    
!!! example "Usage Examples"

    ```ruby
    strategy.auto_load(except: [:common, :random])
    ```
    
    ```ruby
    strategy.auto_load(only: [:rsi, :macd])
    ```
??? info "Source Location"
    `lib/sqa/strategy.rb:79`

---

### `#available()`

Returns all available strategy classes in the SQA::Strategy namespace.


!!! success "Returns"

    **Type:** `Array<Class>`

    

    Array of strategy classes
!!! example "Usage Examples"

    ```ruby
    SQA::Strategy.new.available
    # => [SQA::Strategy::RSI, SQA::Strategy::MACD, ...]
    ```
??? info "Source Location"
    `lib/sqa/strategy.rb:108`

---

## 📝 Attributes

### 🔄 `strategies` <small>read/write</small>

