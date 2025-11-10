# SQA::DataFrame Architecture Review

## Executive Summary

**CRITICAL ISSUES FOUND**: The DataFrame architecture has several fundamental design flaws that prevent it from working correctly. The primary issue is a **type mismatch** between `Polars::DataFrame` and `SQA::DataFrame` throughout the data flow.

---

## Architecture Overview

### Intended Design
```
Data Sources (Alpha Vantage, Yahoo)
  → SQA::DataFrame (wrapper)
  → SQA::Stock (@df attribute)
  → CSV persistence
```

### Actual Implementation
```
Data Sources (Alpha Vantage, Yahoo)
  → Polars::DataFrame (raw) ❌
  → SQA::Stock (@df attribute expects SQA::DataFrame)
  → Type confusion and method errors
```

---

## Critical Issues

### 1. **Missing `SQA::DataFrame.load()` Method**

**Location**: `lib/sqa/stock.rb:52`

```ruby
@df = SQA::DataFrame.load(source: @df_path, transformers: @transformers)
```

**Problem**: This method doesn't exist in `SQA::DataFrame`

**Available methods**:
- `from_csv_file(source, mapping: {}, transformers: {})`
- `from_json_file(source, mapping: {}, transformers: {})`
- `from_aofh(aofh, mapping: {}, transformers: {})`

**None match the signature**: `.load(source:, transformers:)`

**Impact**: Stock loading from cached CSV files will fail with `NoMethodError`

---

### 2. **Data Source Adapters Return Wrong Type**

**AlphaVantage** (`lib/sqa/data_frame/alpha_vantage.rb:71`):
```ruby
def self.recent(ticker, full: false, from_date: nil)
  # ...
  df = Polars.read_csv(...)  # Returns Polars::DataFrame
  # ...
  df  # ❌ Returns Polars::DataFrame instead of SQA::DataFrame
end
```

**YahooFinance** (`lib/sqa/data_frame/yahoo_finance.rb:68`):
```ruby
def self.recent(ticker)
  data = rows.map { ... }.compact
  Polars::DataFrame.new(data)  # ❌ Returns Polars::DataFrame
end
```

**Expected by Stock** (`lib/sqa/stock.rb:54-55`):
```ruby
@df = @klass.recent(@ticker, full: true)  # Expects SQA::DataFrame
@df.write_csv(@df_path)                    # Works (Polars has write_csv)
```

**But later** (`lib/sqa/stock.rb:63-67`):
```ruby
@df.column("timestamp").last  # ❌ Polars doesn't have .column() method
@df.concat(df2)               # ❌ Polars uses .vstack(), not .concat()
```

---

### 3. **TRANSFORMERS Never Applied**

**Defined but unused** (`lib/sqa/data_frame/alpha_vantage.rb:25-32`):
```ruby
TRANSFORMERS = {
  HEADERS[1] => -> (v) { v.to_f.round(3) },
  HEADERS[2] => -> (v) { v.to_f.round(3) },
  # ...
}
```

**Where they should be used**:
- Transformers are loaded in Stock (line 20) but never passed to adapters
- Adapters return raw Polars::DataFrame without transformations
- `SQA::DataFrame.initialize()` accepts transformers but adapters bypass it

---

### 4. **HEADER_MAPPING Never Applied**

**AlphaVantage** (`lib/sqa/data_frame/alpha_vantage.rb:15-23`):
```ruby
HEADER_MAPPING = {
  "date"            => HEADERS[0],  # :timestamp
  "open"            => HEADERS[1],  # :open_price
  "adjusted_close"  => HEADERS[5],  # :adj_close_price
  # ...
}
```

**Problem**:
- Alpha Vantage CSV has columns: `timestamp, open, high, low, close, volume`
- Mapping says rename "date" → :timestamp, but Alpha Vantage already uses "timestamp"
- Mapping says rename "adjusted_close" → :adj_close_price, but Alpha Vantage uses "adjusted close" (space!)
- **The mapping is NEVER applied** - data comes through with original column names

---

### 5. **Method Name Mismatches**

**SQA::DataFrame defines** (`lib/sqa/data_frame.rb`):
- `.concat!()` (line 59) - with bang, modifies in place
- `.append!()` (line 45) - with bang

**Stock.rb calls** (`lib/sqa/stock.rb:67`):
```ruby
@df.concat(df2)  # ❌ No bang - doesn't exist
```

**Polars::DataFrame has**:
- `.vstack()` - for vertical stacking
- No `.concat()` or `.concat!()`

---

### 6. **Column Access Method Confusion**

**Stock.rb line 63**:
```ruby
from_date = Date.parse(@df.column("timestamp").last)
```

**Problem**:
- `Polars::DataFrame` uses **indexing**: `df["column_name"]` or `df.get_column("name")`
- There is NO `.column()` method on Polars::DataFrame
- Should be: `@df["timestamp"].last` or `@df.get_column("timestamp").to_a.last`

---

### 7. **CSV Round-Trip Broken**

**Save flow** (`lib/sqa/stock.rb:55`):
```ruby
@df.write_csv(@df_path)  # Works if @df is Polars::DataFrame
```

**Load flow** (`lib/sqa/stock.rb:52`):
```ruby
@df = SQA::DataFrame.load(source: @df_path, transformers: @transformers)  # ❌ Method doesn't exist
```

**What should happen**:
```ruby
# Should use one of these:
@df = SQA::DataFrame.from_csv_file(@df_path, transformers: @transformers)
# But signature is: from_csv_file(source, mapping: {}, transformers: {})
# The load() call passes transformers: which doesn't match mapping:
```

---

## Data Flow Analysis

### First Load (no cached files)

```
1. Stock.new(ticker: 'AAPL', source: :alpha_vantage)
2. load_or_create_data()  → Creates SQA::DataFrame::Data metadata
3. update_the_dataframe() → Line 54
4. @klass.recent(@ticker, full: true)
   ↓
5. AlphaVantage.recent('AAPL', full: true)
6. Polars.read_csv(StringIO.new(csv_response))  → Polars::DataFrame
7. Returns Polars::DataFrame ❌
   ↓
8. @df = Polars::DataFrame  ← Type mismatch!
9. @df.write_csv(@df_path)  → Works (Polars has this method)
```

**Result**: First load appears to work, but @df is wrong type

### Subsequent Load (with cached CSV)

```
1. Stock.new(ticker: 'AAPL')
2. load_or_create_data()  → Loads metadata from JSON
3. update_the_dataframe() → Line 52
4. @df = SQA::DataFrame.load(...)  ❌ NoMethodError: undefined method 'load'
   CRASH!
```

### Update Flow (incremental data)

```
1. update_dataframe_with_recent_data() → Line 63
2. from_date = Date.parse(@df.column("timestamp").last)
   ❌ NoMethodError: undefined method 'column' for Polars::DataFrame
   CRASH!
```

---

## Why This Wasn't Caught

1. **First-time loads** appear to work because Polars::DataFrame has `write_csv`
2. **CSV files are created** successfully
3. **Second load fails** when trying to use non-existent `.load()` method
4. **Updates fail** when trying to use non-existent `.column()` method
5. **No integration tests** covering the full load→save→reload→update cycle

---

## Required Fixes

### Fix 1: Adapters Must Return SQA::DataFrame

**alpha_vantage.rb** (line 71):
```ruby
# BEFORE:
df

# AFTER:
SQA::DataFrame.new(df)
```

**yahoo_finance.rb** (line 68):
```ruby
# BEFORE:
Polars::DataFrame.new(data)

# AFTER:
polars_df = Polars::DataFrame.new(data)
SQA::DataFrame.new(polars_df)
```

### Fix 2: Add SQA::DataFrame.load() Method

**data_frame.rb** (add to class methods):
```ruby
def self.load(source:, transformers: {}, mapping: {})
  df = Polars.read_csv(source)
  new(df, mapping: mapping, transformers: transformers)
end
```

### Fix 3: Fix Method Calls in Stock.rb

**Line 63**:
```ruby
# BEFORE:
from_date = Date.parse(@df.column("timestamp").last)

# AFTER:
from_date = Date.parse(@df["timestamp"].to_a.last)
```

**Line 67**:
```ruby
# BEFORE:
@df.concat(df2)

# AFTER:
@df.concat!(df2)  # Use the bang version defined in SQA::DataFrame
```

### Fix 4: Apply HEADER_MAPPING

**alpha_vantage.rb** needs to:
1. Receive raw CSV with Alpha Vantage headers
2. Rename columns using HEADER_MAPPING
3. Apply TRANSFORMERS
4. Return SQA::DataFrame

**Current code doesn't do any of this!**

### Fix 5: Check Alpha Vantage CSV Format

Need to verify what Alpha Vantage actually returns:
- Column names
- Data types
- Header format

Then ensure HEADER_MAPPING matches reality.

---

## Testing Recommendations

### Unit Tests Needed

1. **Test adapter return types**:
   ```ruby
   result = SQA::DataFrame::AlphaVantage.recent('IBM')
   assert_instance_of SQA::DataFrame, result
   ```

2. **Test CSV round-trip**:
   ```ruby
   df = SQA::DataFrame.from_csv_file('test.csv')
   df.to_csv('test2.csv')
   df2 = SQA::DataFrame.load(source: 'test2.csv')
   assert_equal df.columns, df2.columns
   ```

3. **Test column access**:
   ```ruby
   df = SQA::DataFrame.new(data)
   assert_respond_to df, :[]
   assert_equal expected, df["column_name"].to_a
   ```

4. **Test transformers**:
   ```ruby
   transformers = { price: ->(v) { v.to_f.round(2) } }
   df = SQA::DataFrame::AlphaVantage.recent('IBM')
   # Verify transformers were applied
   ```

### Integration Tests Needed

1. **Full stock load cycle**:
   ```ruby
   # First load (no cache)
   stock1 = SQA::Stock.new(ticker: 'AAPL')

   # Second load (from cache)
   stock2 = SQA::Stock.new(ticker: 'AAPL')

   # Update with new data
   stock2.update_dataframe_with_recent_data
   ```

---

## Impact Assessment

### Severity: **CRITICAL** 🔴

### Affected Components:
- ✅ First-time stock loads (works by accident)
- ❌ Cached stock loads (crashes on .load())
- ❌ Stock updates (crashes on .column())
- ❌ Data transformations (never applied)
- ❌ Column renaming (never applied)
- ❌ Any code expecting SQA::DataFrame methods

### User Impact:
- **sqa-cli** will fail on second run when cache exists
- **Data integrity** - transformers not applied means wrong data types
- **Column names** - inconsistent between sources
- **Performance** - can't use SQA::DataFrame optimizations

---

## Recommendations

1. **Immediate**: Add `.load()` method to unblock cached loads
2. **High Priority**: Fix adapter return types
3. **High Priority**: Fix Stock method calls (.column, .concat)
4. **Medium**: Apply transformers in adapters
5. **Medium**: Apply header mapping in adapters
6. **Low**: Add comprehensive integration tests
7. **Low**: Consider redesigning to be more explicit about type conversions

---

## Additional Observations

### Design Confusion

The architecture shows signs of evolution from different data sources:

1. **Originally designed for Daru** (mentions in docs/data_frame.md)
2. **Migrated to Polars** (current implementation)
3. **Wrapper pattern incomplete** (SQA::DataFrame wraps Polars but inconsistently)

### Missing Functionality

**Stock.rb line 73**:
```ruby
def to_s
  "#{ticker} with #{@df.height} data points from #{@df["timestamp"].first} to #{@df["timestamp"].last}"
end
```

This suggests:
- Direct column access with `[]`
- `.height` method
- `.first` and `.last` on series

These work for **Polars::DataFrame** but inconsistent with `.column()` call on line 63.

---

## Conclusion

The DataFrame architecture has **fundamental type safety issues** that prevent it from working correctly beyond the first load. The wrapper pattern is incomplete, and there's confusion between when to use `Polars::DataFrame` methods vs `SQA::DataFrame` methods.

**Root Cause**: Adapters return raw `Polars::DataFrame` instead of wrapping in `SQA::DataFrame`, but the rest of the codebase assumes the wrapper exists.

**Recommended Action**:
1. Fix adapters to return `SQA::DataFrame`
2. Add missing `.load()` method
3. Fix method calls in Stock
4. Add integration tests
5. Document the type contract clearly
