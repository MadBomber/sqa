# 📦 SQA::Strategy::KBS

!!! abstract "Source Information"
    **Defined in:** [`lib/sqa/strategy/kbs_strategy.rb:50`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy/kbs_strategy.rb#L50)
    
    **Inherits from:** `Object`

## 🏭 Class Methods

### `.trade(vector)`

Main strategy interface - compatible with SQA::Strategy framework




??? info "Source Location"
    [`lib/sqa/strategy/kbs_strategy.rb:62`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy/kbs_strategy.rb#L62)

---

## 🔨 Instance Methods

### `#kb()`

Returns the value of attribute kb.




??? info "Source Location"
    [`lib/sqa/strategy/kbs_strategy.rb:51`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy/kbs_strategy.rb#L51)

---

### `#default_rules_loaded()`

Returns the value of attribute default_rules_loaded.




??? info "Source Location"
    [`lib/sqa/strategy/kbs_strategy.rb:51`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy/kbs_strategy.rb#L51)

---

### `#initialize(load_defaults: = true)`


!!! success "Returns"

    **Type:** `KBS`

    

    a new instance of KBS

??? info "Source Location"
    [`lib/sqa/strategy/kbs_strategy.rb:53`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy/kbs_strategy.rb#L53)

---

### `#execute(vector)`

Execute strategy with given market data




??? info "Source Location"
    [`lib/sqa/strategy/kbs_strategy.rb:68`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy/kbs_strategy.rb#L68)

---

### `#add_rule(name, &block)`

Add a custom trading rule

Example:
  add_rule :buy_dip do
    on :rsi, { value: ->(v) { v < 30 } }
    on :macd, { signal: :bullish }
    perform { kb.assert(:signal, { action: :buy, confidence: :high }) }
  end

Note: Use `kb.assert` in perform blocks, not just `assert`




??? info "Source Location"
    [`lib/sqa/strategy/kbs_strategy.rb:92`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy/kbs_strategy.rb#L92)

---

### `#assert_fact(type, attributes = {})`

Assert a fact into working memory




??? info "Source Location"
    [`lib/sqa/strategy/kbs_strategy.rb:105`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy/kbs_strategy.rb#L105)

---

### `#query_facts(type, pattern = {})`

Query facts from working memory




??? info "Source Location"
    [`lib/sqa/strategy/kbs_strategy.rb:110`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy/kbs_strategy.rb#L110)

---

### `#print_facts()`

Print current working memory (for debugging)




??? info "Source Location"
    [`lib/sqa/strategy/kbs_strategy.rb:115`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy/kbs_strategy.rb#L115)

---

### `#print_rules()`

Print all rules (for debugging)




??? info "Source Location"
    [`lib/sqa/strategy/kbs_strategy.rb:120`](https://github.com/madbomber/sqa/blob/main/lib/sqa/strategy/kbs_strategy.rb#L120)

---

## 📝 Attributes

### 👁️ `kb` <small>read-only</small>

Returns the value of attribute kb.

### 👁️ `default_rules_loaded` <small>read-only</small>

Returns the value of attribute default_rules_loaded.

