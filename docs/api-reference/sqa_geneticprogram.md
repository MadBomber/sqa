# 📦 SQA::GeneticProgram

!!! abstract "Source Information"
    **Defined in:** `lib/sqa/gp.rb:35`
    
    **Inherits from:** `Object`

## 🔨 Instance Methods

### `#stock()`

Returns the value of attribute stock.




??? info "Source Location"
    `lib/sqa/gp.rb:54`

---

### `#population()`

Returns the value of attribute population.




??? info "Source Location"
    `lib/sqa/gp.rb:54`

---

### `#best_individual()`

Returns the value of attribute best_individual.




??? info "Source Location"
    `lib/sqa/gp.rb:54`

---

### `#generation()`

Returns the value of attribute generation.




??? info "Source Location"
    `lib/sqa/gp.rb:54`

---

### `#history()`

Returns the value of attribute history.




??? info "Source Location"
    `lib/sqa/gp.rb:54`

---

### `#population_size()`

Returns the value of attribute population_size.




??? info "Source Location"
    `lib/sqa/gp.rb:55`

---

### `#population_size=(value)`

Sets the attribute population_size

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute population_size to. |


??? info "Source Location"
    `lib/sqa/gp.rb:55`

---

### `#generations()`

Returns the value of attribute generations.




??? info "Source Location"
    `lib/sqa/gp.rb:55`

---

### `#generations=(value)`

Sets the attribute generations

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute generations to. |


??? info "Source Location"
    `lib/sqa/gp.rb:55`

---

### `#mutation_rate()`

Returns the value of attribute mutation_rate.




??? info "Source Location"
    `lib/sqa/gp.rb:55`

---

### `#mutation_rate=(value)`

Sets the attribute mutation_rate

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute mutation_rate to. |


??? info "Source Location"
    `lib/sqa/gp.rb:55`

---

### `#crossover_rate()`

Returns the value of attribute crossover_rate.




??? info "Source Location"
    `lib/sqa/gp.rb:55`

---

### `#crossover_rate=(value)`

Sets the attribute crossover_rate

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute crossover_rate to. |


??? info "Source Location"
    `lib/sqa/gp.rb:55`

---

### `#elitism_count()`

Returns the value of attribute elitism_count.




??? info "Source Location"
    `lib/sqa/gp.rb:55`

---

### `#elitism_count=(value)`

Sets the attribute elitism_count

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `value` | `Any` | the value to set the attribute elitism_count to. |


??? info "Source Location"
    `lib/sqa/gp.rb:55`

---

### `#initialize(stock:, population_size: = 50, generations: = 100, mutation_rate: = 0.15, crossover_rate: = 0.7, elitism_count: = 2)`


!!! success "Returns"

    **Type:** `GeneticProgram`

    

    a new instance of GeneticProgram

??? info "Source Location"
    `lib/sqa/gp.rb:57`

---

### `#define_genes(**constraints)`

Define the parameter space for evolution

Example:
  gp.define_genes(
    indicator: [:rsi, :macd, :stoch],
    period: (5..30).to_a,
    buy_threshold: (20..40).to_a,
    sell_threshold: (60..80).to_a
  )




??? info "Source Location"
    `lib/sqa/gp.rb:82`

---

### `#fitness(&block)`

Define how to evaluate fitness for an individual

The block receives an individual's genes hash and should return
a numeric fitness value (higher is better)

Example:
  gp.fitness do |genes|
    backtest = SQA::Backtest.new(
      stock: stock,
      strategy: create_strategy_from_genes(genes),
      initial_capital: 10_000
    )
    results = backtest.run
    results.total_return # Higher return = higher fitness
  end




??? info "Source Location"
    `lib/sqa/gp.rb:102`

---

### `#evolve()`

Run the genetic algorithm evolution




??? info "Source Location"
    `lib/sqa/gp.rb:108`

---

## 📝 Attributes

### 👁️ `stock` <small>read-only</small>

Returns the value of attribute stock.

### 👁️ `population` <small>read-only</small>

Returns the value of attribute population.

### 👁️ `best_individual` <small>read-only</small>

Returns the value of attribute best_individual.

### 👁️ `generation` <small>read-only</small>

Returns the value of attribute generation.

### 👁️ `history` <small>read-only</small>

Returns the value of attribute history.

### 🔄 `population_size` <small>read/write</small>

Returns the value of attribute population_size.

### 🔄 `generations` <small>read/write</small>

Returns the value of attribute generations.

### 🔄 `mutation_rate` <small>read/write</small>

Returns the value of attribute mutation_rate.

### 🔄 `crossover_rate` <small>read/write</small>

Returns the value of attribute crossover_rate.

### 🔄 `elitism_count` <small>read/write</small>

Returns the value of attribute elitism_count.

