# 📦 SQA::Backtest

!!! abstract "Source Information"
    **Defined in:** [`lib/sqa/backtest.rb:7`](https://github.com/madbomber/sqa/blob/main/lib/sqa/backtest.rb#L7)
    
    **Inherits from:** `Object`

## 🔨 Instance Methods

### `#stock()`

Returns the value of attribute stock.




??? info "Source Location"
    [`lib/sqa/backtest.rb:8`](https://github.com/madbomber/sqa/blob/main/lib/sqa/backtest.rb#L8)

---

### `#strategy()`

Returns the value of attribute strategy.




??? info "Source Location"
    [`lib/sqa/backtest.rb:8`](https://github.com/madbomber/sqa/blob/main/lib/sqa/backtest.rb#L8)

---

### `#portfolio()`

Returns the value of attribute portfolio.




??? info "Source Location"
    [`lib/sqa/backtest.rb:8`](https://github.com/madbomber/sqa/blob/main/lib/sqa/backtest.rb#L8)

---

### `#results()`

Returns the value of attribute results.




??? info "Source Location"
    [`lib/sqa/backtest.rb:8`](https://github.com/madbomber/sqa/blob/main/lib/sqa/backtest.rb#L8)

---

### `#equity_curve()`

Returns the value of attribute equity_curve.




??? info "Source Location"
    [`lib/sqa/backtest.rb:8`](https://github.com/madbomber/sqa/blob/main/lib/sqa/backtest.rb#L8)

---

### `#initialize(stock:, strategy:, start_date: = nil, end_date: = nil, initial_capital: = 10_000.0, commission: = 0.0, position_size: = :all_cash)`

Initialize a backtest

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `stock` | `SQA::Stock` | Stock to backtest |
    | `strategy` | `SQA::Strategy, Proc` | Strategy or callable that returns :buy, :sell, or :hold |
    | `start_date` | `Date, String` | Start date for backtest |
    | `end_date` | `Date, String` | End date for backtest |
    | `initial_capital` | `Float` | Starting capital |
    | `commission` | `Float` | Commission per trade |
    | `position_size` | `Symbol, Float` | :all_cash or fraction of portfolio per trade |
!!! success "Returns"

    **Type:** `Backtest`

    

    a new instance of Backtest

??? info "Source Location"
    [`lib/sqa/backtest.rb:85`](https://github.com/madbomber/sqa/blob/main/lib/sqa/backtest.rb#L85)

---

### `#run()`

Run the backtest


!!! success "Returns"

    **Type:** `Results`

    

    Backtest results
!!! example "Usage Examples"

    ```ruby
    stock = SQA::Stock.new(ticker: 'AAPL')
    backtest = SQA::Backtest.new(
      stock: stock,
      strategy: SQA::Strategy::RSI,
      initial_capital: 10_000,
      commission: 1.0
    )
    results = backtest.run
    puts results.summary
    # => Total Return: 15.5%
    #    Sharpe Ratio: 1.2
    #    Max Drawdown: -8.3%
    #    Win Rate: 65%
    ```
    
    ```ruby
    backtest = SQA::Backtest.new(
      stock: stock,
      strategy: SQA::Strategy::MACD,
      start_date: '2023-01-01',
      end_date: '2023-12-31'
    )
    results = backtest.run
    results.total_return  # => 0.155 (15.5%)
    ```
    
    ```ruby
    results = backtest.run
    backtest.equity_curve.each do |point|
      puts "#{point[:date]}: $#{point[:value]}"
    end
    ```
??? info "Source Location"
    [`lib/sqa/backtest.rb:102`](https://github.com/madbomber/sqa/blob/main/lib/sqa/backtest.rb#L102)

---

## 📝 Attributes

### 👁️ `stock` <small>read-only</small>

Returns the value of attribute stock.

### 👁️ `strategy` <small>read-only</small>

Returns the value of attribute strategy.

### 👁️ `portfolio` <small>read-only</small>

Returns the value of attribute portfolio.

### 👁️ `results` <small>read-only</small>

Returns the value of attribute results.

### 👁️ `equity_curve` <small>read-only</small>

Returns the value of attribute equity_curve.

