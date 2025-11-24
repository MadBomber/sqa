# 📦 ApiError

!!! note "Description"
    Raised when an external API returns an error response.
    Automatically logs the error using debug_me before raising.

!!! abstract "Source Information"
    **Defined in:** `lib/sqa/errors.rb:67`
    
    **Inherits from:** `RuntimeError`

## 🏭 Class Methods

### `.raise(why)`

Raises an ApiError with debug logging.

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `why` | `String` | The error message from the API |


??? info "Source Location"
    `lib/sqa/errors.rb:72`

---

## 📝 Attributes

