# 📦 SQA::DataFetchError

!!! note "Description"
    Raised when unable to fetch data from a data source (API, file, etc.).
    Wraps the original exception for debugging purposes.

!!! abstract "Source Information"
    **Defined in:** [`lib/sqa/errors.rb:26`](https://github.com/madbomber/sqa/blob/main/lib/sqa/errors.rb#L26)
    
    **Inherits from:** `StandardError`

## 🔨 Instance Methods

### `#original_error()`


!!! success "Returns"

    **Type:** `Exception, nil`

    

    The original exception that caused this error

??? info "Source Location"
    [`lib/sqa/errors.rb:28`](https://github.com/madbomber/sqa/blob/main/lib/sqa/errors.rb#L28)

---

### `#initialize(message, original: = nil)`

Creates a new DataFetchError.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `message` | `String` | Error message describing the fetch failure |
    | `original` | `Exception, nil` | The original exception that was caught |
!!! success "Returns"

    **Type:** `DataFetchError`

    

    a new instance of DataFetchError

??? info "Source Location"
    [`lib/sqa/errors.rb:34`](https://github.com/madbomber/sqa/blob/main/lib/sqa/errors.rb#L34)

---

## 📝 Attributes

### 👁️ `original_error` <small>read-only</small>

