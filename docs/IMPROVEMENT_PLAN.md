# SQA Gem Improvement Plan

**Created:** 2025-11-23
**Status:** Pending Review
**Scope:** 17 files, 31 discrete changes across 4 phases
**Impact Analysis:** Verified against sqa_demo-sinatra and sqa-cli

---

## Overview

This plan addresses code quality issues identified in a comprehensive review of the SQA codebase. All changes have been verified for backward compatibility with dependent gems.

### Dependent Gems Analyzed

| Gem | Impact | Notes |
|-----|--------|-------|
| sqa_demo-sinatra | ✅ All changes safe | Explicitly calls `SQA.init` |
| sqa-cli | ✅ All changes safe | Requires coordinated update (see separate plan) |

---

## Phase 1: Critical Security & Correctness Fixes

**Priority:** Immediate
**Dependencies:** None
**Files:** 4
**Breaking Changes:** None

### Task 1.1: Fix Shell Injection Vulnerability

**File:** `lib/sqa/config.rb`
**Line:** 123

```ruby
# FROM:
`touch #{config_file}`

# TO:
FileUtils.touch(config_file)
```

**Requires:** Verify `require 'fileutils'` is present
**Risk:** None
**Test:** Verify config file creation works

---

### Task 1.2: Replace Deprecated `has_key?` with `key?`

| File | Line | Change |
|------|------|--------|
| `lib/sqa/stock.rb` | 176 | `temp.has_key? "Information"` → `temp.key?("Information")` |
| `lib/sqa/ticker.rb` | 74 | `has_key?` → `key?` |
| `lib/sqa/config.rb` | 111 | `has_key?` → `key?` |

**Risk:** None
**Test:** Existing tests pass

---

### Task 1.3: Fix String Raises to Proper Exception Classes

**File:** `lib/sqa/errors.rb` - Add new classes:

```ruby
class DataFetchError < StandardError
  attr_reader :original_error
  def initialize(message, original: nil)
    @original_error = original
    super(message)
  end
end

class ConfigurationError < StandardError; end
```

**File:** `lib/sqa/stock.rb` (Lines 106-108):

```ruby
# FROM:
raise "Unable to fetch data for #{@ticker}...Error: #{e.message}"

# TO:
raise SQA::DataFetchError.new("Unable to fetch data for #{@ticker}: #{e.message}", original: e)
```

**File:** `lib/sqa/init.rb` (Line 34):

```ruby
# FROM:
raise('Alpha Vantage API key not set...')

# TO:
raise SQA::ConfigurationError, 'Alpha Vantage API key not set...'
```

**Risk:** Low - More informative errors, generic rescue still catches them
**Test:** Add tests for new exception classes

---

### Task 1.4: Replace Bare Rescues with Specific Exception Types

**File:** `lib/sqa/stock.rb`

| Line | From | To |
|------|------|-----|
| 54 | `rescue => e` | `rescue StandardError => e` |
| 106 | `rescue => e` | `rescue Faraday::Error, StandardError => e` |
| 128 | `rescue => e` | `rescue StandardError => e` |
| 143 | `rescue` (bare) | `rescue ArgumentError, Date::Error => e` |
| 154 | `rescue => e` | `rescue StandardError => e` |

**Risk:** Low - Won't catch `Interrupt`/`SystemExit` (correct behavior)
**Test:** Verify error handling for expected failures

---

## Phase 2: Code Quality & Best Practices

**Priority:** High
**Dependencies:** Phase 1 complete
**Files:** 7
**Breaking Changes:** None

### Task 2.1: Replace Class Variables with Thread-Safe Alternatives

**File:** `lib/sqa/init.rb` (Lines 5-6, 34, 47-48, 52, 55)

```ruby
# FROM:
@@data_dir = nil
@@av_api_key = nil

# TO:
class << self
  attr_accessor :data_dir, :av_api_key
end
@data_dir = nil
@av_api_key = nil
```

**File:** `lib/sqa/stock.rb` (Lines 196, 219)

```ruby
# FROM:
@@top = nil
@@bottom = nil

# TO:
class << self
  def top
    @top ||= fetch_top_data
  end

  def bottom
    @bottom ||= fetch_bottom_data
  end

  def reset_cache!
    @top = nil
    @bottom = nil
  end
end
```

**File:** `lib/sqa/ticker.rb` (Lines 16, 61, 67, 72) - Similar pattern

**Risk:** Medium - Changes shared state behavior
**Test:** Add thread-safety tests, verify existing tests pass

---

### Task 2.2: Remove `puts` from Error Classes

**File:** `lib/sqa/errors.rb` (Lines 5-14, 18-26)

```ruby
# FROM:
class ApiError < RuntimeError
  def self.raise(why)
    puts "="*64
    puts "== API Error"
    puts why
    puts "="*64
    super
  end
end

# TO:
class ApiError < RuntimeError
  def self.raise(why)
    debug_me {"API Error: #{why}"}
    super
  end
end
```

**Requires:** `debug_me` gem available (per CLAUDE.md guidelines)
**Risk:** Low
**Test:** Verify errors still raise correctly

---

### Task 2.3: Remove `puts` from Production Code

**File:** `lib/sqa/sector_analyzer.rb` (Lines 145-147)

```ruby
# FROM:
puts "=" * 70
puts "Discovering patterns for #{sector.to_s.upcase} sector"
puts "=" * 70

# TO:
debug_me {"Discovering patterns for #{sector.to_s.upcase} sector"}
```

**Risk:** None
**Test:** Verify sector analysis works

---

### Task 2.4: Simplify `method_missing` in DataFrame

**File:** `lib/sqa/data_frame.rb` (Lines 164-173)

**Option A - Simplified Dynamic (Recommended):**

```ruby
# FROM:
def method_missing(method_name, *args, &block)
  if @data.respond_to?(method_name)
    self.class.send(:define_method, method_name) do |*method_args, &method_block|
      @data.send(method_name, *method_args, &method_block)
    end
    send(method_name, *args, &block)
  else
    super
  end
end

# TO:
def method_missing(method_name, *args, &block)
  return super unless @data.respond_to?(method_name)
  @data.send(method_name, *args, &block)
end
```

**Risk:** Low - Removes dynamic method definition, keeps delegation
**Test:** Run all DataFrame tests

---

### Task 2.5: Remove Unused Parameters

**File:** `lib/sqa/data_frame.rb` (Lines 200-209)

```ruby
# FROM:
def from_aofh(aofh, mapping: {}, transformers: {})

# TO:
def from_aofh(aofh)
```

**Risk:** None - Parameters were never used
**Test:** Verify `from_aofh` works

---

### Task 2.6: Fix Type Checking Pattern

**File:** `lib/sqa/strategy.rb` (Line 11)

```ruby
# FROM:
raise BadParameterError unless [Class, Method].include? a_strategy.class

# TO:
raise BadParameterError unless a_strategy.is_a?(Class) || a_strategy.is_a?(Method)
```

**Risk:** None
**Test:** Existing tests pass

---

### Task 2.7: Remove Magic Placeholder Code

**File:** `lib/sqa/stock.rb` (Line 48)

```ruby
# FROM:
@data = SQA::DataFrame::Data.new(ticker: @ticker, source: @source, indicators: { xyzzy: "Magic" })

# TO:
@data = SQA::DataFrame::Data.new(ticker: @ticker, source: @source, indicators: {})
```

**Risk:** None
**Test:** Verify stock initialization

---

## Phase 3: Architecture & Design Improvements

**Priority:** Medium
**Dependencies:** Phases 1-2 complete
**Files:** 3
**Breaking Changes:** None (Task 3.1 revised)

### Task 3.1: Add Deprecation Warning for Auto-Initialization (REVISED)

**Original Plan:** Remove `SQA::Config.reset` at require time
**Revision:** Keep auto-init but add deprecation warning for future removal

**File:** `lib/sqa/config.rb` (Line 195)

```ruby
# FROM:
SQA::Config.reset

# TO:
unless SQA::Config.instance_variable_get(:@initialized)
  warn "[SQA DEPRECATION] Auto-initialization at require time will be removed in v1.0. " \
       "Please call SQA.init explicitly in your application startup."
  SQA::Config.reset
end
```

**Rationale:** sqa-cli does not explicitly call `SQA.init` and would break. This gives dependent gems time to update.

**Coordination Required:**
- Update sqa-cli to call `SQA.init` explicitly (see separate plan)
- Remove auto-init in SQA v1.0

**Risk:** None - Backward compatible with warning
**Test:** Verify warning appears, initialization still works

---

### Task 3.2: Add Ascending Order Enforcement

**File:** `lib/sqa/data_frame.rb` (around line 85)

```ruby
def concat_and_deduplicate!(other_df, sort_column: "timestamp", descending: false)
  if descending
    warn "[SQA WARNING] TA-Lib requires ascending (oldest-first) order. Forcing descending: false"
    descending = false
  end
  # ... rest of method
end
```

**Risk:** Low - Prevents silent data ordering bugs
**Test:** Add test for descending=true warning

---

### Task 3.3: Extract Faraday Connection to Configurable Dependency

**File:** `lib/sqa/stock.rb` (Line 6)

```ruby
# FROM:
CONNECTION = Faraday.new(url: "https://www.alphavantage.co")

# TO:
class << self
  def connection
    @connection ||= default_connection
  end

  def connection=(conn)
    @connection = conn
  end

  def default_connection
    Faraday.new(url: "https://www.alphavantage.co")
  end

  def reset_connection!
    @connection = nil
  end
end
```

**Benefit:** Allows mocking in tests, custom configurations
**Risk:** Low - Default behavior unchanged
**Test:** Add tests for connection injection

---

## Phase 4: Documentation & Cleanup

**Priority:** Low
**Dependencies:** Phases 1-3 complete
**Files:** Multiple
**Breaking Changes:** None

### Task 4.1: Resolve TODO Comments

Create GitHub issues for each TODO, update code with issue references:

| File | Line | TODO |
|------|------|------|
| `lib/sqa.rb` | 4, 16-17 | Investigate |
| `lib/sqa/config.rb` | 23 (FIXME), 36, 43, 47, 96 | Create issues |
| `lib/api/alpha_vantage_api.rb` | 6 | Investigate |
| `lib/sqa/strategy.rb` | 24 | Investigate |
| `lib/sqa/init.rb` | 21 | Investigate |

**Deliverable:** GitHub issues created, TODOs updated

---

### Task 4.2: Fix Error Class Documentation

**File:** `lib/sqa/errors.rb`

Fix duplicated/incorrect docstring for `NotImplemented` class.

---

### Task 4.3: Standardize Method Naming (Optional)

**File:** `lib/sqa/stock.rb`

| Current | Proposed |
|---------|----------|
| `update_the_dataframe` | `update_dataframe` |

**Decision:** Add deprecation alias or rename directly?
**Risk:** Medium if renaming without deprecation

---

## Implementation Order

```
Week 1: Phase 1 (Critical)
├── Task 1.1: Shell injection fix
├── Task 1.2: has_key? → key?
├── Task 1.3: String raises → exceptions
└── Task 1.4: Bare rescues → specific types

Week 2: Phase 2 (Quality) - Part 1
├── Task 2.1: Class variables → instance variables
├── Task 2.2: Remove puts from errors
└── Task 2.3: Remove puts from production

Week 3: Phase 2 (Quality) - Part 2
├── Task 2.4: Simplify method_missing
├── Task 2.5: Remove unused parameters
├── Task 2.6: Fix type checking
└── Task 2.7: Remove magic placeholder

Week 4: Phase 3 (Architecture)
├── Task 3.1: Add deprecation warning (coordinate with sqa-cli)
├── Task 3.2: Ascending order enforcement
└── Task 3.3: Configurable connection

Ongoing: Phase 4 (Docs)
├── Task 4.1-4.3: Documentation cleanup
```

---

## Testing Strategy

### Per-Phase Testing
- Run `rake test` after each task
- Verify no regressions

### Integration Testing
After all phases:
1. Install updated SQA locally
2. Run sqa_demo-sinatra test suite
3. Run sqa-cli test suite
4. Manual smoke testing of key features

### Test Coverage Additions
- New exception classes (Task 1.3)
- Thread-safety for class instance variables (Task 2.1)
- Connection injection (Task 3.3)
- Ascending order warning (Task 3.2)

---

## Rollback Strategy

Each phase creates separate commits allowing:
- Independent review per phase
- Easy rollback if issues discovered
- Incremental release if needed

---

## Version Strategy

| Release | Changes |
|---------|---------|
| v0.0.33 | Current release |
| v0.0.34 | Phases 1-2 (non-breaking fixes) |
| v0.0.35 | Phase 3 (with deprecation warning) |
| v1.0.0 | Remove auto-initialization (breaking) |

---

## Coordination with Dependent Gems

### sqa-cli
- **Before SQA v0.0.35:** Update sqa-cli to call `SQA.init` explicitly
- See: `sqa-cli/docs/SQA_COMPATIBILITY_UPDATE.md`

### sqa_demo-sinatra
- **No changes required** - Already calls `SQA.init` explicitly

---

## Approval Checklist

- [ ] User approves Phase 1 tasks
- [ ] User approves Phase 2 tasks
- [ ] User approves Phase 3 tasks (revised)
- [ ] User approves Phase 4 tasks
- [ ] sqa-cli update plan approved
- [ ] Ready to begin implementation
