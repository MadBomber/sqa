# 📦 SQA::Stream

!!! abstract "Source Information"
    **Defined in:** [`lib/sqa/stream.rb:39`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stream.rb#L39)
    
    **Inherits from:** `Object`

## 🔨 Instance Methods

### `#ticker()`

Returns the value of attribute ticker.




??? info "Source Location"
    [`lib/sqa/stream.rb:40`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stream.rb#L40)

---

### `#window_size()`

Returns the value of attribute window_size.




??? info "Source Location"
    [`lib/sqa/stream.rb:40`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stream.rb#L40)

---

### `#strategies()`

Returns the value of attribute strategies.




??? info "Source Location"
    [`lib/sqa/stream.rb:40`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stream.rb#L40)

---

### `#data_buffer()`

Returns the value of attribute data_buffer.




??? info "Source Location"
    [`lib/sqa/stream.rb:40`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stream.rb#L40)

---

### `#indicator_cache()`

Returns the value of attribute indicator_cache.




??? info "Source Location"
    [`lib/sqa/stream.rb:40`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stream.rb#L40)

---

### `#initialize(ticker:, window_size: = 100, strategies: = [])`


!!! success "Returns"

    **Type:** `Stream`

    

    a new instance of Stream

??? info "Source Location"
    [`lib/sqa/stream.rb:42`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stream.rb#L42)

---

### `#add_strategy(strategy)`

Add a strategy to the stream processor




??? info "Source Location"
    [`lib/sqa/stream.rb:65`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stream.rb#L65)

---

### `#on_signal(&block)`

Register callback for trading signals

Example:
  stream.on_signal do |signal, data|
    puts "#{signal.upcase} at $#{data[:price]}"
  end




??? info "Source Location"
    [`lib/sqa/stream.rb:78`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stream.rb#L78)

---

### `#on_update(&block)`

Register callback for price updates

Example:
  stream.on_update do |data|
    puts "Price updated: $#{data[:price]}"
  end




??? info "Source Location"
    [`lib/sqa/stream.rb:89`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stream.rb#L89)

---

### `#update(price:, volume: = nil, high: = nil, low: = nil, timestamp: = Time.now)`

Update stream with new market data

Required fields: price
Optional fields: volume, high, low, timestamp




??? info "Source Location"
    [`lib/sqa/stream.rb:98`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stream.rb#L98)

---

### `#current_price()`

Get current price




??? info "Source Location"
    [`lib/sqa/stream.rb:136`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stream.rb#L136)

---

### `#recent_prices(count = nil)`

Get recent prices




??? info "Source Location"
    [`lib/sqa/stream.rb:141`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stream.rb#L141)

---

### `#recent_volumes(count = nil)`

Get recent volumes




??? info "Source Location"
    [`lib/sqa/stream.rb:148`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stream.rb#L148)

---

### `#indicator(name, **options)`

Calculate or retrieve cached indicator

Example:
  rsi = stream.indicator(:rsi, period: 14)
  sma = stream.indicator(:sma, period: 20)




??? info "Source Location"
    [`lib/sqa/stream.rb:159`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stream.rb#L159)

---

### `#current_signal()`

Get current trading signal from last strategy execution




??? info "Source Location"
    [`lib/sqa/stream.rb:177`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stream.rb#L177)

---

### `#stats()`

Get statistics about the stream




??? info "Source Location"
    [`lib/sqa/stream.rb:182`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stream.rb#L182)

---

### `#reset()`

Reset the stream (clear all data)




??? info "Source Location"
    [`lib/sqa/stream.rb:199`](https://github.com/madbomber/sqa/blob/main/lib/sqa/stream.rb#L199)

---

## 📝 Attributes

### 👁️ `ticker` <small>read-only</small>

Returns the value of attribute ticker.

### 👁️ `window_size` <small>read-only</small>

Returns the value of attribute window_size.

### 👁️ `strategies` <small>read-only</small>

Returns the value of attribute strategies.

### 👁️ `data_buffer` <small>read-only</small>

Returns the value of attribute data_buffer.

### 👁️ `indicator_cache` <small>read-only</small>

Returns the value of attribute indicator_cache.

