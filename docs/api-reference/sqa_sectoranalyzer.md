# 📦 SQA::SectorAnalyzer

!!! abstract "Source Information"
    **Defined in:** [`lib/sqa/sector_analyzer.rb:26`](https://github.com/madbomber/sqa/blob/main/lib/sqa/sector_analyzer.rb#L26)
    
    **Inherits from:** `Object`

## 🔨 Instance Methods

### `#blackboards()`

Returns the value of attribute blackboards.




??? info "Source Location"
    [`lib/sqa/sector_analyzer.rb:40`](https://github.com/madbomber/sqa/blob/main/lib/sqa/sector_analyzer.rb#L40)

---

### `#stocks_by_sector()`

Returns the value of attribute stocks_by_sector.




??? info "Source Location"
    [`lib/sqa/sector_analyzer.rb:40`](https://github.com/madbomber/sqa/blob/main/lib/sqa/sector_analyzer.rb#L40)

---

### `#initialize(db_dir: = '/tmp/sqa_sectors')`


!!! success "Returns"

    **Type:** `SectorAnalyzer`

    

    a new instance of SectorAnalyzer

??? info "Source Location"
    [`lib/sqa/sector_analyzer.rb:42`](https://github.com/madbomber/sqa/blob/main/lib/sqa/sector_analyzer.rb#L42)

---

### `#add_stock(stock, sector:)`

Add a stock to sector analysis

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `stock` | `SQA::Stock, String` | Stock object or ticker |
    | `sector` | `Symbol` | Sector classification |


??? info "Source Location"
    [`lib/sqa/sector_analyzer.rb:62`](https://github.com/madbomber/sqa/blob/main/lib/sqa/sector_analyzer.rb#L62)

---

### `#discover_sector_patterns(sector, stocks, **options)`

Discover patterns for an entire sector

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `sector` | `Symbol` | Sector to analyze |
    | `stocks` | `Array<SQA::Stock>` | Stock objects to analyze |
    | `options` | `Hash` | Pattern discovery options |
!!! success "Returns"

    **Type:** `Array<Hash>`

    

    Sector-wide patterns

??? info "Source Location"
    [`lib/sqa/sector_analyzer.rb:86`](https://github.com/madbomber/sqa/blob/main/lib/sqa/sector_analyzer.rb#L86)

---

### `#detect_sector_regime(sector, stocks)`

Detect sector regime

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `sector` | `Symbol` | Sector to analyze |
    | `stocks` | `Array<SQA::Stock>` | Stock objects |
!!! success "Returns"

    **Type:** `Hash`

    

    Sector regime information

??? info "Source Location"
    [`lib/sqa/sector_analyzer.rb:146`](https://github.com/madbomber/sqa/blob/main/lib/sqa/sector_analyzer.rb#L146)

---

### `#query_sector(sector, fact_type, pattern = {})`

Query sector blackboard

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `sector` | `Symbol` | Sector to query |
    | `fact_type` | `Symbol` | Type of fact to query |
    | `pattern` | `Hash` | Pattern to match |
!!! success "Returns"

    **Type:** `Array<KBS::Fact>`

    

    Matching facts

??? info "Source Location"
    [`lib/sqa/sector_analyzer.rb:190`](https://github.com/madbomber/sqa/blob/main/lib/sqa/sector_analyzer.rb#L190)

---

### `#print_sector_summary(sector)`

Print sector summary

!!! info "Parameters"

    | Name | Type | Description |
    |------|------|-------------|
    | `sector` | `Symbol` | Sector to summarize |


??? info "Source Location"
    [`lib/sqa/sector_analyzer.rb:202`](https://github.com/madbomber/sqa/blob/main/lib/sqa/sector_analyzer.rb#L202)

---

## 📝 Attributes

### 👁️ `blackboards` <small>read-only</small>

Returns the value of attribute blackboards.

### 👁️ `stocks_by_sector` <small>read-only</small>

Returns the value of attribute stocks_by_sector.

