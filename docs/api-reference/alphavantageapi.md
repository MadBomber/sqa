# 📦 AlphaVantageAPI

!!! abstract "Source Information"
    **Defined in:** `lib/api/alpha_vantage_api.rb:11`
    
    **Inherits from:** `Object`

## 🔨 Instance Methods

### `#initialize(api_key)`


!!! success "Returns"

    **Type:** `AlphaVantageAPI`

    

    a new instance of AlphaVantageAPI

??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:14`

---

### `#query(function:, symbol: = nil, interval: = nil, time_period: = nil, series_type: = nil, market: = nil, **extra)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:19`

---

### `#ad(symbol:, interval:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:45`

---

### `#adosc(symbol:, interval:, fastperiod:, slowperiod:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:49`

---

### `#adx(symbol:, interval:, time_period:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:53`

---

### `#all_commodities(interval:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:57`

---

### `#aluminum(interval:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:61`

---

### `#apo(symbol:, interval:, series_type:, fastperiod:, matype:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:65`

---

### `#aroon(symbol:, interval:, time_period:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:69`

---

### `#balance_sheet(symbol:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:73`

---

### `#crypto_intraday(symbol:, market:, interval:, outputsize: = nil, datatype: = nil)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:77`

---

### `#currency_exchange_rate(from_currency:, to_currency:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:81`

---

### `#earnings(symbol:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:85`

---

### `#time_series_daily(symbol:, outputsize: = nil, datatype: = nil)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:89`

---

### `#adxr(symbol:, interval:, time_period:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:93`

---

### `#atr(symbol:, interval:, time_period:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:97`

---

### `#bbands(symbol:, interval:, time_period:, series_type:, nbdevup:, nbdevdn:, matype: = nil)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:101`

---

### `#bop(symbol:, interval:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:105`

---

### `#cash_flow(symbol:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:109`

---

### `#cci(symbol:, interval:, time_period:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:113`

---

### `#cmo(symbol:, interval:, time_period:, series_type:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:117`

---

### `#dema(symbol:, interval:, time_period:, series_type:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:121`

---

### `#dx(symbol:, interval:, time_period:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:125`

---

### `#earnings_calendar(symbol: = nil, horizon: = nil)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:129`

---

### `#ema(symbol:, interval:, time_period:, series_type:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:133`

---

### `#federal_funds_rate(interval:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:137`

---

### `#ht_dcperiod(symbol:, interval:, series_type:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:141`

---

### `#ht_dcphase(symbol:, interval:, series_type:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:145`

---

### `#ht_phasor(symbol:, interval:, series_type:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:149`

---

### `#ht_sine(symbol:, interval:, series_type:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:153`

---

### `#ht_trendline(symbol:, interval:, series_type:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:157`

---

### `#ht_trendmode(symbol:, interval:, series_type:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:161`

---

### `#income_statement(symbol:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:165`

---

### `#aronosc(symbol:, interval:, time_period:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:170`

---

### `#brent(interval:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:174`

---

### `#coffee(interval:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:178`

---

### `#copper(interval:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:182`

---

### `#corn(interval:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:186`

---

### `#cotton(interval:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:190`

---

### `#cpi(interval:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:194`

---

### `#durables()`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:198`

---

### `#inflation()`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:202`

---

### `#ipo_calendar()`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:206`

---

### `#kama(symbol:, interval:, time_period:, series_type:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:210`

---

### `#listing_status(date: = nil, state: = nil)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:214`

---

### `#market_status()`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:218`

---

### `#natural_gas(interval:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:222`

---

### `#news_sentiment(tickers:, time_from: = nil, limit: = nil)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:226`

---

### `#nonfarm_payroll()`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:230`

---

### `#real_gdp(interval:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:234`

---

### `#real_gdp_per_capita()`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:238`

---

### `#retail_sales()`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:242`

---

### `#sugar(interval:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:246`

---

### `#symbol_search(keywords:, datatype: = nil)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:250`

---

### `#top_gainers_losers()`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:254`

---

### `#treasury_yield(interval:, maturity:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:258`

---

### `#unemployment()`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:262`

---

### `#wheat(interval:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:266`

---

### `#wti(interval:)`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:270`

---

### `#digital_currency_daily(symbol:, market:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:274`

---

### `#fx_daily(from_symbol:, to_symbol:, outputsize: = nil, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:278`

---

### `#global_quote(symbol:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:282`

---

### `#time_series_daily_adjusted(symbol:, outputsize: = nil, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:286`

---

### `#macd(symbol:, interval:, series_type:, time_period:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:290`

---

### `#fx_intraday(from_symbol:, to_symbol:, interval:, outputsize: = nil, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:295`

---

### `#digital_currency_monthly(symbol:, market:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:299`

---

### `#digital_currency_weekly(symbol:, market:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:303`

---

### `#time_series_intraday(symbol:, interval:, outputsize: = nil, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:307`

---

### `#time_series_monthly(symbol:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:311`

---

### `#time_series_weekly(symbol:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:315`

---

### `#macd_ext(symbol:, interval:, series_type:, fastperiod: = nil, slowperiod: = nil, signalperiod: = nil, matype: = nil, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:319`

---

### `#rsi(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:327`

---

### `#fx_monthly(from_symbol:, to_symbol:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:331`

---

### `#fx_weekly(from_symbol:, to_symbol:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:335`

---

### `#mama(symbol:, interval:, series_type:, fastlimit:, slowlimit:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:339`

---

### `#mfi(symbol:, interval:, time_period:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:343`

---

### `#midpoint(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:347`

---

### `#midprice(symbol:, interval:, time_period:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:351`

---

### `#minus_di(symbol:, interval:, time_period:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:355`

---

### `#minus_dm(symbol:, interval:, time_period:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:359`

---

### `#mom(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:363`

---

### `#natr(symbol:, interval:, time_period:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:367`

---

### `#obv(symbol:, interval:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:371`

---

### `#overview(symbol:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:375`

---

### `#plus_di(symbol:, interval:, time_period:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:379`

---

### `#plus_dm(symbol:, interval:, time_period:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:383`

---

### `#ppo(symbol:, interval:, series_type:, fastperiod:, slowperiod: = nil, matype: = nil, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:387`

---

### `#roc(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:391`

---

### `#rocr(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:395`

---

### `#stoch(symbol:, interval:, fastkperiod: = nil, slowkperiod: = nil, slowdperiod: = nil, slowkmatype: = nil, slowdmatype: = nil, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:399`

---

### `#sar(symbol:, interval:, acceleration:, maximum:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:403`

---

### `#sma(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:407`

---

### `#stochf(symbol:, interval:, fastkperiod: = nil, fastdperiod: = nil, fastdmatype: = nil, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:411`

---

### `#t3(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:415`

---

### `#tema(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:419`

---

### `#time_series_monthly_adjusted(symbol:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:423`

---

### `#time_series_weekly_adjusted(symbol:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:427`

---

### `#trange(symbol:, interval:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:431`

---

### `#trima(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:435`

---

### `#trix(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:439`

---

### `#ultosc(symbol:, interval:, timeperiod1: = nil, timeperiod2: = nil, timeperiod3: = nil, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:443`

---

### `#vwap(symbol:, interval:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:447`

---

### `#willr(symbol:, interval:, time_period:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:451`

---

### `#wma(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    `lib/api/alpha_vantage_api.rb:455`

---

## 📝 Attributes

