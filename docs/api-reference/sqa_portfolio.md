# 📦 SQA::Portfolio

!!! abstract "Source Information"
    **Defined in:** [`lib/sqa/portfolio.rb:7`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L7)
    
    **Inherits from:** `Object`

## 🏭 Class Methods

### `.load_from_csv(filename)`

Load portfolio from CSV file

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `filename` | `String` | Path to CSV file |


??? info "Source Location"
    [`lib/sqa/portfolio.rb:236`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L236)

---

## 🔨 Instance Methods

### `#positions()`

Returns the value of attribute positions.




??? info "Source Location"
    [`lib/sqa/portfolio.rb:8`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L8)

---

### `#positions=(value)`

Sets the attribute positions

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute positions to. |


??? info "Source Location"
    [`lib/sqa/portfolio.rb:8`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L8)

---

### `#trades()`

Returns the value of attribute trades.




??? info "Source Location"
    [`lib/sqa/portfolio.rb:8`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L8)

---

### `#trades=(value)`

Sets the attribute trades

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute trades to. |


??? info "Source Location"
    [`lib/sqa/portfolio.rb:8`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L8)

---

### `#cash()`

Returns the value of attribute cash.




??? info "Source Location"
    [`lib/sqa/portfolio.rb:8`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L8)

---

### `#cash=(value)`

Sets the attribute cash

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute cash to. |


??? info "Source Location"
    [`lib/sqa/portfolio.rb:8`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L8)

---

### `#initial_cash()`

Returns the value of attribute initial_cash.




??? info "Source Location"
    [`lib/sqa/portfolio.rb:8`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L8)

---

### `#initial_cash=(value)`

Sets the attribute initial_cash

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute initial_cash to. |


??? info "Source Location"
    [`lib/sqa/portfolio.rb:8`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L8)

---

### `#commission()`

Returns the value of attribute commission.




??? info "Source Location"
    [`lib/sqa/portfolio.rb:8`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L8)

---

### `#commission=(value)`

Sets the attribute commission

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute commission to. |


??? info "Source Location"
    [`lib/sqa/portfolio.rb:8`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L8)

---

### `#initialize(initial_cash: = 10_000.0, commission: = 0.0)`


!!! success "Returns"

    **Type:** `Portfolio`

    

    a new instance of Portfolio

??? info "Source Location"
    [`lib/sqa/portfolio.rb:41`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L41)

---

### `#buy(ticker, shares:, price:, date: = Date.today)`

Buy shares of a stock

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `ticker` | `String` | Stock ticker symbol |
    | `shares` | `Integer` | Number of shares to buy |
    | `price` | `Float` | Price per share |
    | `date` | `Date` | Date of trade |
!!! success "Returns"

    **Type:** `Trade`

    

    The executed trade
!!! example "Usage Examples"

    ```ruby
    portfolio = SQA::Portfolio.new(initial_cash: 10_000, commission: 1.0)
    trade = portfolio.buy('AAPL', shares: 10, price: 150.0)
    trade.action  # => :buy
    trade.total   # => 1500.0
    portfolio.cash  # => 8499.0 (10_000 - 1500 - 1.0 commission)
    ```
    
    ```ruby
    portfolio.buy('AAPL', shares: 10, price: 150.0)
    portfolio.buy('MSFT', shares: 5, price: 300.0)
    portfolio.positions.size  # => 2
    ```
??? info "Source Location"
    [`lib/sqa/portfolio.rb:55`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L55)

---

### `#sell(ticker, shares:, price:, date: = Date.today)`

Sell shares of a stock

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `ticker` | `String` | Stock ticker symbol |
    | `shares` | `Integer` | Number of shares to sell |
    | `price` | `Float` | Price per share |
    | `date` | `Date` | Date of trade |
!!! success "Returns"

    **Type:** `Trade`

    

    The executed trade
!!! example "Usage Examples"

    ```ruby
    portfolio = SQA::Portfolio.new(initial_cash: 10_000, commission: 1.0)
    portfolio.buy('AAPL', shares: 10, price: 150.0)
    trade = portfolio.sell('AAPL', shares: 10, price: 160.0)
    trade.total  # => 1600.0
    portfolio.cash  # => 8498.0 + 1599.0 = 10097.0 (after commissions)
    ```
    
    ```ruby
    portfolio.buy('AAPL', shares: 100, price: 150.0)
    portfolio.sell('AAPL', shares: 50, price: 160.0)  # Sell half
    portfolio.position('AAPL').shares  # => 50
    ```
??? info "Source Location"
    [`lib/sqa/portfolio.rb:98`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L98)

---

### `#position(ticker)`

Get current position for a ticker

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `ticker` | `String` | Stock ticker symbol |
!!! success "Returns"

    **Type:** `Position, nil`

    

    The position or nil if not found

??? info "Source Location"
    [`lib/sqa/portfolio.rb:135`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L135)

---

### `#all_positions()`

Get all current positions


!!! success "Returns"

    **Type:** `Hash`

    

    Hash of ticker => Position

??? info "Source Location"
    [`lib/sqa/portfolio.rb:141`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L141)

---

### `#value(current_prices = {})`

Calculate total portfolio value

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `current_prices` | `Hash` | Hash of ticker => current_price |
!!! success "Returns"

    **Type:** `Float`

    

    Total portfolio value (cash + positions)
!!! example "Usage Examples"

    ```ruby
    portfolio = SQA::Portfolio.new(initial_cash: 10_000)
    portfolio.buy('AAPL', shares: 10, price: 150.0)
    portfolio.buy('MSFT', shares: 5, price: 300.0)
    
    current_prices = { 'AAPL' => 160.0, 'MSFT' => 310.0 }
    portfolio.value(current_prices)  # => 10_000 - 1500 - 1500 + 1600 + 1550 = 10_150
    ```
    
    ```ruby
    portfolio.value  # Uses purchase prices if no current prices provided
    ```
??? info "Source Location"
    [`lib/sqa/portfolio.rb:148`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L148)

---

### `#profit_loss(current_prices = {})`

Calculate total profit/loss across all positions

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `current_prices` | `Hash` | Hash of ticker => current_price |
!!! success "Returns"

    **Type:** `Float`

    

    Total P&L

??? info "Source Location"
    [`lib/sqa/portfolio.rb:160`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L160)

---

### `#profit_loss_percent(current_prices = {})`

Calculate profit/loss percentage

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `current_prices` | `Hash` | Hash of ticker => current_price |
!!! success "Returns"

    **Type:** `Float`

    

    P&L percentage

??? info "Source Location"
    [`lib/sqa/portfolio.rb:167`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L167)

---

### `#total_return(current_prices = {})`

Calculate total return (including dividends if tracked)

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `current_prices` | `Hash` | Hash of ticker => current_price |
!!! success "Returns"

    **Type:** `Float`

    

    Total return as decimal (e.g., 0.15 for 15%)

??? info "Source Location"
    [`lib/sqa/portfolio.rb:175`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L175)

---

### `#trade_history()`

Get trade history


!!! success "Returns"

    **Type:** `Array<Trade>`

    

    Array of all trades

??? info "Source Location"
    [`lib/sqa/portfolio.rb:182`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L182)

---

### `#summary(current_prices = {})`

Get summary statistics

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `current_prices` | `Hash` | Hash of ticker => current_price |
!!! success "Returns"

    **Type:** `Hash`

    

    Summary statistics
!!! example "Usage Examples"

    ```ruby
    portfolio = SQA::Portfolio.new(initial_cash: 10_000, commission: 1.0)
    portfolio.buy('AAPL', shares: 10, price: 150.0)
    portfolio.sell('AAPL', shares: 5, price: 160.0)
    
    summary = portfolio.summary({ 'AAPL' => 165.0 })
    summary[:initial_cash]        # => 10_000.0
    summary[:current_cash]        # => 8798.0
    summary[:positions_count]     # => 1
    summary[:total_value]         # => 9623.0
    summary[:profit_loss_percent] # => -3.77%
    summary[:total_trades]        # => 2
    summary[:buy_trades]          # => 1
    summary[:sell_trades]         # => 1
    ```
??? info "Source Location"
    [`lib/sqa/portfolio.rb:189`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L189)

---

### `#save_to_csv(filename)`

Save portfolio to CSV file

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `filename` | `String` | Path to CSV file |


??? info "Source Location"
    [`lib/sqa/portfolio.rb:206`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L206)

---

### `#save_trades_to_csv(filename)`

Save trade history to CSV file

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `filename` | `String` | Path to CSV file |


??? info "Source Location"
    [`lib/sqa/portfolio.rb:217`](https://github.com/madbomber/sqa/blob/main/lib/sqa/portfolio.rb#L217)

---

## 📝 Attributes

### 🔄 `positions` <small>read/write</small>

Returns the value of attribute positions.

### 🔄 `trades` <small>read/write</small>

Returns the value of attribute trades.

### 🔄 `cash` <small>read/write</small>

Returns the value of attribute cash.

### 🔄 `initial_cash` <small>read/write</small>

Returns the value of attribute initial_cash.

### 🔄 `commission` <small>read/write</small>

Returns the value of attribute commission.

