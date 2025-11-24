# 📦 SQA::Config

!!! note "Description"
    Configuration class for SQA settings.
    Extends Hashie::Dash for property-based configuration with coercion.

!!! abstract "Source Information"
    **Defined in:** [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)
    
    **Inherits from:** `Hashie::Dash`

## 🏭 Class Methods

### `.reset()`

Resets the configuration to default values.
Creates a new Config instance and assigns it to SQA.config.


!!! success "Returns"

    **Type:** `SQA::Config`

    

    The new config instance

??? info "Source Location"
    [`lib/sqa/config.rb:255`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L255)

---

### `.initialized?()`

Returns whether the configuration has been initialized.


!!! success "Returns"

    **Type:** `Boolean`

    

    true if reset has been called

??? info "Source Location"
    [`lib/sqa/config.rb:263`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L263)

---

## 🔨 Instance Methods

### `#command()`


!!! success "Returns"

    **Type:** `String, nil`

    

    Current command (nil, 'analysis', or 'web')

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#command=(value)`


!!! success "Returns"

    **Type:** `String, nil`

    

    Current command (nil, 'analysis', or 'web')

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#config_file()`


!!! success "Returns"

    **Type:** `String, nil`

    

    Path to configuration file

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#config_file=(value)`


!!! success "Returns"

    **Type:** `String, nil`

    

    Path to configuration file

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#dump_config()`


!!! success "Returns"

    **Type:** `String, nil`

    

    Path to dump current configuration

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#dump_config=(value)`


!!! success "Returns"

    **Type:** `String, nil`

    

    Path to dump current configuration

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#data_dir()`


!!! success "Returns"

    **Type:** `String`

    

    Directory for data storage (default: ~/sqa_data)

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#data_dir=(value)`


!!! success "Returns"

    **Type:** `String`

    

    Directory for data storage (default: ~/sqa_data)

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#portfolio_filename()`


!!! success "Returns"

    **Type:** `String`

    

    Portfolio CSV filename (default: portfolio.csv)

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#portfolio_filename=(value)`


!!! success "Returns"

    **Type:** `String`

    

    Portfolio CSV filename (default: portfolio.csv)

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#trades_filename()`


!!! success "Returns"

    **Type:** `String`

    

    Trades CSV filename (default: trades.csv)

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#trades_filename=(value)`


!!! success "Returns"

    **Type:** `String`

    

    Trades CSV filename (default: trades.csv)

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#log_level()`


!!! success "Returns"

    **Type:** `Symbol`

    

    Log level (:debug, :info, :warn, :error, :fatal)

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#log_level=(value)`


!!! success "Returns"

    **Type:** `Symbol`

    

    Log level (:debug, :info, :warn, :error, :fatal)

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#debug()`


!!! success "Returns"

    **Type:** `Boolean`

    

    Enable debug mode

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#debug=(value)`


!!! success "Returns"

    **Type:** `Boolean`

    

    Enable debug mode

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#verbose()`


!!! success "Returns"

    **Type:** `Boolean`

    

    Enable verbose output

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#verbose=(value)`


!!! success "Returns"

    **Type:** `Boolean`

    

    Enable verbose output

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#plotting_library()`


!!! success "Returns"

    **Type:** `Symbol`

    

    Plotting library to use (:gruff)

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#plotting_library=(value)`


!!! success "Returns"

    **Type:** `Symbol`

    

    Plotting library to use (:gruff)

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#lazy_update()`


!!! success "Returns"

    **Type:** `Boolean`

    

    Skip API updates if cached data exists

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#lazy_update=(value)`


!!! success "Returns"

    **Type:** `Boolean`

    

    Skip API updates if cached data exists

??? info "Source Location"
    [`lib/sqa/config.rb:54`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L54)

---

### `#initialize(a_hash = {})`

Creates a new Config instance with optional initial values.
Automatically applies environment variable overrides.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `a_hash` | `Hash` | Initial configuration values |
!!! success "Returns"

    **Type:** `Config`

    

    a new instance of Config

??? info "Source Location"
    [`lib/sqa/config.rb:120`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L120)

---

### `#debug?()`

Returns whether debug mode is enabled.


!!! success "Returns"

    **Type:** `Boolean`

    

    true if debug mode is on

??? info "Source Location"
    [`lib/sqa/config.rb:127`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L127)

---

### `#verbose?()`

Returns whether verbose mode is enabled.


!!! success "Returns"

    **Type:** `Boolean`

    

    true if verbose mode is on

??? info "Source Location"
    [`lib/sqa/config.rb:131`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L131)

---

### `#from_file()`

Loads configuration from a file.
Supports YAML (.yml, .yaml), TOML (.toml), and JSON (.json) formats.


!!! success "Returns"

    **Type:** `void`

    

??? info "Source Location"
    [`lib/sqa/config.rb:141`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L141)

---

### `#dump_file()`

Writes current configuration to a file.
Format is determined by file extension.


!!! success "Returns"

    **Type:** `void`

    

??? info "Source Location"
    [`lib/sqa/config.rb:178`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L178)

---

### `#inject_additional_properties()`

Injects additional properties from plugins.
Allows external code to register new configuration options.


!!! success "Returns"

    **Type:** `void`

    

??? info "Source Location"
    [`lib/sqa/config.rb:206`](https://github.com/madbomber/sqa/blob/main/lib/sqa/config.rb#L206)

---

## 📝 Attributes

### 🔄 `command` <small>read/write</small>

### 🔄 `config_file` <small>read/write</small>

### 🔄 `dump_config` <small>read/write</small>

### 🔄 `data_dir` <small>read/write</small>

### 🔄 `portfolio_filename` <small>read/write</small>

### 🔄 `trades_filename` <small>read/write</small>

### 🔄 `log_level` <small>read/write</small>

### 🔄 `debug` <small>read/write</small>

### 🔄 `verbose` <small>read/write</small>

### 🔄 `plotting_library` <small>read/write</small>

### 🔄 `lazy_update` <small>read/write</small>

