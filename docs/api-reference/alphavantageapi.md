# 📦 AlphaVantageAPI

!!! abstract "Source Information"
    **Defined in:** [`lib/api/alpha_vantage_api.rb:11`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L11)
    
    **Inherits from:** `Object`

## 🔨 Instance Methods

### `#initialize(api_key)`


!!! success "Returns"

    **Type:** `AlphaVantageAPI`

    

    a new instance of AlphaVantageAPI

??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:14`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L14)

---

### `#query(function:, symbol: = nil, interval: = nil, time_period: = nil, series_type: = nil, market: = nil, **extra)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:19`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L19)

---

### `#ad(symbol:, interval:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:45`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L45)

---

### `#adosc(symbol:, interval:, fastperiod:, slowperiod:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:49`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L49)

---

### `#adx(symbol:, interval:, time_period:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:53`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L53)

---

### `#all_commodities(interval:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:57`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L57)

---

### `#aluminum(interval:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:61`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L61)

---

### `#apo(symbol:, interval:, series_type:, fastperiod:, matype:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:65`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L65)

---

### `#aroon(symbol:, interval:, time_period:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:69`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L69)

---

### `#balance_sheet(symbol:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:73`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L73)

---

### `#crypto_intraday(symbol:, market:, interval:, outputsize: = nil, datatype: = nil)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:77`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L77)

---

### `#currency_exchange_rate(from_currency:, to_currency:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:81`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L81)

---

### `#earnings(symbol:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:85`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L85)

---

### `#time_series_daily(symbol:, outputsize: = nil, datatype: = nil)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:89`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L89)

---

### `#adxr(symbol:, interval:, time_period:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:93`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L93)

---

### `#atr(symbol:, interval:, time_period:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:97`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L97)

---

### `#bbands(symbol:, interval:, time_period:, series_type:, nbdevup:, nbdevdn:, matype: = nil)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:101`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L101)

---

### `#bop(symbol:, interval:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:105`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L105)

---

### `#cash_flow(symbol:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:109`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L109)

---

### `#cci(symbol:, interval:, time_period:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:113`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L113)

---

### `#cmo(symbol:, interval:, time_period:, series_type:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:117`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L117)

---

### `#dema(symbol:, interval:, time_period:, series_type:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:121`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L121)

---

### `#dx(symbol:, interval:, time_period:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:125`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L125)

---

### `#earnings_calendar(symbol: = nil, horizon: = nil)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:129`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L129)

---

### `#ema(symbol:, interval:, time_period:, series_type:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:133`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L133)

---

### `#federal_funds_rate(interval:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:137`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L137)

---

### `#ht_dcperiod(symbol:, interval:, series_type:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:141`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L141)

---

### `#ht_dcphase(symbol:, interval:, series_type:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:145`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L145)

---

### `#ht_phasor(symbol:, interval:, series_type:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:149`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L149)

---

### `#ht_sine(symbol:, interval:, series_type:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:153`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L153)

---

### `#ht_trendline(symbol:, interval:, series_type:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:157`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L157)

---

### `#ht_trendmode(symbol:, interval:, series_type:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:161`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L161)

---

### `#income_statement(symbol:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:165`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L165)

---

### `#aronosc(symbol:, interval:, time_period:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:170`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L170)

---

### `#brent(interval:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:174`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L174)

---

### `#coffee(interval:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:178`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L178)

---

### `#copper(interval:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:182`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L182)

---

### `#corn(interval:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:186`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L186)

---

### `#cotton(interval:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:190`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L190)

---

### `#cpi(interval:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:194`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L194)

---

### `#durables()`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:198`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L198)

---

### `#inflation()`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:202`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L202)

---

### `#ipo_calendar()`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:206`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L206)

---

### `#kama(symbol:, interval:, time_period:, series_type:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:210`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L210)

---

### `#listing_status(date: = nil, state: = nil)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:214`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L214)

---

### `#market_status()`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:218`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L218)

---

### `#natural_gas(interval:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:222`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L222)

---

### `#news_sentiment(tickers:, time_from: = nil, limit: = nil)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:226`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L226)

---

### `#nonfarm_payroll()`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:230`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L230)

---

### `#real_gdp(interval:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:234`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L234)

---

### `#real_gdp_per_capita()`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:238`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L238)

---

### `#retail_sales()`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:242`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L242)

---

### `#sugar(interval:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:246`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L246)

---

### `#symbol_search(keywords:, datatype: = nil)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:250`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L250)

---

### `#top_gainers_losers()`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:254`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L254)

---

### `#treasury_yield(interval:, maturity:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:258`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L258)

---

### `#unemployment()`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:262`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L262)

---

### `#wheat(interval:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:266`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L266)

---

### `#wti(interval:)`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:270`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L270)

---

### `#digital_currency_daily(symbol:, market:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:274`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L274)

---

### `#fx_daily(from_symbol:, to_symbol:, outputsize: = nil, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:278`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L278)

---

### `#global_quote(symbol:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:282`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L282)

---

### `#time_series_daily_adjusted(symbol:, outputsize: = nil, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:286`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L286)

---

### `#macd(symbol:, interval:, series_type:, time_period:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:290`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L290)

---

### `#fx_intraday(from_symbol:, to_symbol:, interval:, outputsize: = nil, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:295`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L295)

---

### `#digital_currency_monthly(symbol:, market:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:299`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L299)

---

### `#digital_currency_weekly(symbol:, market:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:303`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L303)

---

### `#time_series_intraday(symbol:, interval:, outputsize: = nil, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:307`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L307)

---

### `#time_series_monthly(symbol:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:311`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L311)

---

### `#time_series_weekly(symbol:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:315`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L315)

---

### `#macd_ext(symbol:, interval:, series_type:, fastperiod: = nil, slowperiod: = nil, signalperiod: = nil, matype: = nil, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:319`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L319)

---

### `#rsi(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:327`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L327)

---

### `#fx_monthly(from_symbol:, to_symbol:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:331`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L331)

---

### `#fx_weekly(from_symbol:, to_symbol:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:335`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L335)

---

### `#mama(symbol:, interval:, series_type:, fastlimit:, slowlimit:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:339`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L339)

---

### `#mfi(symbol:, interval:, time_period:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:343`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L343)

---

### `#midpoint(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:347`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L347)

---

### `#midprice(symbol:, interval:, time_period:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:351`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L351)

---

### `#minus_di(symbol:, interval:, time_period:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:355`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L355)

---

### `#minus_dm(symbol:, interval:, time_period:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:359`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L359)

---

### `#mom(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:363`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L363)

---

### `#natr(symbol:, interval:, time_period:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:367`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L367)

---

### `#obv(symbol:, interval:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:371`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L371)

---

### `#overview(symbol:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:375`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L375)

---

### `#plus_di(symbol:, interval:, time_period:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:379`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L379)

---

### `#plus_dm(symbol:, interval:, time_period:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:383`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L383)

---

### `#ppo(symbol:, interval:, series_type:, fastperiod:, slowperiod: = nil, matype: = nil, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:387`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L387)

---

### `#roc(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:391`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L391)

---

### `#rocr(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:395`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L395)

---

### `#stoch(symbol:, interval:, fastkperiod: = nil, slowkperiod: = nil, slowdperiod: = nil, slowkmatype: = nil, slowdmatype: = nil, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:399`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L399)

---

### `#sar(symbol:, interval:, acceleration:, maximum:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:403`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L403)

---

### `#sma(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:407`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L407)

---

### `#stochf(symbol:, interval:, fastkperiod: = nil, fastdperiod: = nil, fastdmatype: = nil, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:411`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L411)

---

### `#t3(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:415`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L415)

---

### `#tema(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:419`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L419)

---

### `#time_series_monthly_adjusted(symbol:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:423`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L423)

---

### `#time_series_weekly_adjusted(symbol:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:427`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L427)

---

### `#trange(symbol:, interval:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:431`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L431)

---

### `#trima(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:435`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L435)

---

### `#trix(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:439`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L439)

---

### `#ultosc(symbol:, interval:, timeperiod1: = nil, timeperiod2: = nil, timeperiod3: = nil, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:443`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L443)

---

### `#vwap(symbol:, interval:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:447`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L447)

---

### `#willr(symbol:, interval:, time_period:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:451`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L451)

---

### `#wma(symbol:, interval:, time_period:, series_type:, datatype: = 'json')`




??? info "Source Location"
    [`lib/api/alpha_vantage_api.rb:455`](https://github.com/madbomber/sqa/blob/main/lib/api/alpha_vantage_api.rb#L455)

---

## 📝 Attributes

