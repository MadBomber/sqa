# 📦 SQA::DataFrame::AlphaVantage

!!! abstract "Source Information"
    **Defined in:** [`lib/sqa/data_frame/alpha_vantage.rb:9`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame/alpha_vantage.rb#L9)
    
    **Inherits from:** `Object`

## 🏭 Class Methods

### `.recent(ticker, full: = false, from_date: = nil)`

Get recent data from Alpha Vantage API

ticker String the security to retrieve
full Boolean whether to fetch full history or compact (last 100 days)
from_date Date optional date to fetch data after (for incremental updates)

Returns: SQA::DataFrame sorted in ASCENDING order (oldest to newest)
Note: Alpha Vantage returns data newest-first, but we sort ascending for TA-Lib compatibility




??? info "Source Location"
    [`lib/sqa/data_frame/alpha_vantage.rb:46`](https://github.com/madbomber/sqa/blob/main/lib/sqa/data_frame/alpha_vantage.rb#L46)

---

## 📝 Attributes

