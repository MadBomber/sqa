# alpha_vantage_api.rb

require 'faraday'
require 'json'

# TODO: Reorganize the methods by category
#         Market Data
#         Technical Indicators
#         Trading
#         Economic Indicators
#         Digital and Forex
#


class AlphaVantageAPI
  BASE_URL = 'https://www.alphavantage.co/query'.freeze

  def initialize(api_key)
    @api_key    = api_key
    @connection = Faraday.new(url: BASE_URL)
  end

  def query(  function:,
      symbol:       nil,
      interval:     nil,
      time_period:  nil,
      series_type:  nil,
      market:       nil,
      **extra
    )

    response = @connection.get do |req|
      req.params['apikey']      = @api_key
      req.params['function']    = function
      req.params['symbol']      = symbol      if symbol
      req.params['interval']    = interval    if interval
      req.params['time_period'] = time_period if time_period
      req.params['series_type'] = series_type if series_type
      req.params['market']      = market      if market

      extra.each { |key, value| req.params[key.to_s] = value if value }
    end

    JSON.parse(response.body)
  rescue Faraday::Error => e
    { error: "Failed to retrieve data: #{e.message}" }
  end

  def ad(symbol:, interval:)
    query(function: 'AD', symbol: symbol, interval: interval)
  end

  def adosc(symbol:, interval:, fastperiod:, slowperiod:)
    query(function: 'ADOSC', symbol: symbol, interval: interval, fastperiod: fastperiod, slowperiod: slowperiod)
  end

  def adx(symbol:, interval:, time_period:)
    query(function: 'ADX', symbol: symbol, interval: interval, time_period: time_period)
  end

  def all_commodities(interval:)
    query(function: 'ALL_COMMODITIES', interval: interval)
  end

  def aluminum(interval:)
    query(function: 'ALUMINUM', interval: interval)
  end

  def apo(symbol:, interval:, series_type:, fastperiod:, matype:)
    query(function: 'APO', symbol: symbol, interval: interval, series_type: series_type, fastperiod: fastperiod, matype: matype)
  end

  def aroon(symbol:, interval:, time_period:)
    query(function: 'AROON', symbol: symbol, interval: interval, time_period: time_period)
  end

  def balance_sheet(symbol:)
    query(function: 'BALANCE_SHEET', symbol: symbol)
  end

  def crypto_intraday(symbol:, market:, interval:, outputsize: nil, datatype: nil)
    query(function: 'CRYPTO_INTRADAY', symbol: symbol, market: market, interval: interval, outputsize: outputsize, datatype: datatype)
  end

  def currency_exchange_rate(from_currency:, to_currency:)
    query(function: 'CURRENCY_EXCHANGE_RATE', from_currency: from_currency, to_currency: to_currency)
  end

  def earnings(symbol:)
    query(function: 'EARNINGS', symbol: symbol)
  end

  def time_series_daily(symbol:, outputsize: nil, datatype: nil)
    query(function: 'TIME_SERIES_DAILY', symbol: symbol, outputsize: outputsize, datatype: datatype)
  end

  def adxr(symbol:, interval:, time_period:)
    query(function: 'ADXR', symbol: symbol, interval: interval, time_period: time_period)
  end

  def atr(symbol:, interval:, time_period:)
    query(function: 'ATR', symbol: symbol, interval: interval, time_period: time_period)
  end

  def bbands(symbol:, interval:, time_period:, series_type:, nbdevup:, nbdevdn:, matype: nil)
    query(function: 'BBANDS', symbol: symbol, interval: interval, time_period: time_period, series_type: series_type, nbdevup: nbdevup, nbdevdn: nbdevdn, matype: matype)
  end

  def bop(symbol:, interval:)
    query(function: 'BOP', symbol: symbol, interval: interval)
  end

  def cash_flow(symbol:)
    query(function: 'CASH_FLOW', symbol: symbol)
  end

  def cci(symbol:, interval:, time_period:)
    query(function: 'CCI', symbol: symbol, interval: interval, time_period: time_period)
  end

  def cmo(symbol:, interval:, time_period:, series_type:)
    query(function: 'CMO', symbol: symbol, interval: interval, time_period: time_period, series_type: series_type)
  end

  def dema(symbol:, interval:, time_period:, series_type:)
    query(function: 'DEMA', symbol: symbol, interval: interval, time_period: time_period, series_type: series_type)
  end

  def dx(symbol:, interval:, time_period:)
    query(function: 'DX', symbol: symbol, interval: interval, time_period: time_period)
  end

  def earnings_calendar(symbol: nil, horizon: nil)
    query(function: 'EARNINGS_CALENDAR', symbol: symbol, horizon: horizon)
  end

  def ema(symbol:, interval:, time_period:, series_type:)
    query(function: 'EMA', symbol: symbol, interval: interval, time_period: time_period, series_type: series_type)
  end

  def federal_funds_rate(interval:)
    query(function: 'FEDERAL_FUNDS_RATE', interval: interval)
  end

  def ht_dcperiod(symbol:, interval:, series_type:)
    query(function: 'HT_DCPERIOD', symbol: symbol, interval: interval, series_type: series_type)
  end

  def ht_dcphase(symbol:, interval:, series_type:)
    query(function: 'HT_DCPHASE', symbol: symbol, interval: interval, series_type: series_type)
  end

  def ht_phasor(symbol:, interval:, series_type:)
    query(function: 'HT_PHASOR', symbol: symbol, interval: interval, series_type: series_type)
  end

  def ht_sine(symbol:, interval:, series_type:)
    query(function: 'HT_SINE', symbol: symbol, interval: interval, series_type: series_type)
  end

  def ht_trendline(symbol:, interval:, series_type:)
    query(function: 'HT_TRENDLINE', symbol: symbol, interval: interval, series_type: series_type)
  end

  def ht_trendmode(symbol:, interval:, series_type:)
    query(function: 'HT_TRENDMODE', symbol: symbol, interval: interval, series_type: series_type)
  end

  def income_statement(symbol:)
    query(function: 'INCOME_STATEMENT', symbol: symbol)
  end


  def aronosc(symbol:, interval:, time_period:)
    query(function: 'AROONOSC', symbol: symbol, interval: interval, time_period: time_period)
  end

  def brent(interval:)
    query(function: 'BRENT', interval: interval)
  end

  def coffee(interval:)
    query(function: 'COFFEE', interval: interval)
  end

  def copper(interval:)
    query(function: 'COPPER', interval: interval)
  end

  def corn(interval:)
    query(function: 'CORN', interval: interval)
  end

  def cotton(interval:)
    query(function: 'COTTON', interval: interval)
  end

  def cpi(interval:)
    query(function: 'CPI', interval: interval)
  end

  def durables
    query(function: 'DURABLES')
  end

  def inflation
    query(function: 'INFLATION')
  end

  def ipo_calendar
    query(function: 'IPO_CALENDAR')
  end

  def kama(symbol:, interval:, time_period:, series_type:)
    query(function: 'KAMA', symbol: symbol, interval: interval, time_period: time_period, series_type: series_type)
  end

  def listing_status(date: nil, state: nil)
    query(function: 'LISTING_STATUS', date: date, state: state)
  end

  def market_status
    query(function: 'MARKET_STATUS')
  end

  def natural_gas(interval:)
    query(function: 'NATURAL_GAS', interval: interval)
  end

  def news_sentiment(tickers:, time_from: nil, limit: nil)
    query(function: 'NEWS_SENTIMENT', tickers: tickers, time_from: time_from, limit: limit)
  end

  def nonfarm_payroll
    query(function: 'NONFARM_PAYROLL')
  end

  def real_gdp(interval:)
    query(function: 'REAL_GDP', interval: interval)
  end

  def real_gdp_per_capita
    query(function: 'REAL_GDP_PER_CAPITA')
  end

  def retail_sales
    query(function: 'RETAIL_SALES')
  end

  def sugar(interval:)
    query(function: 'SUGAR', interval: interval)
  end

  def symbol_search(keywords:, datatype: nil)
    query(function: 'SYMBOL_SEARCH', keywords: keywords, datatype: datatype)
  end

  def top_gainers_losers
    query(function: 'TOP_GAINERS_LOSERS')
  end

  def treasury_yield(interval:, maturity:)
    query(function: 'TREASURY_YIELD', interval: interval, maturity: maturity)
  end

  def unemployment
    query(function: 'UNEMPLOYMENT')
  end

  def wheat(interval:)
    query(function: 'WHEAT', interval: interval)
  end

  def wti(interval:)
    query(function: 'WTI', interval: interval)
  end

  def digital_currency_daily(symbol:, market:, datatype: 'json')
    query(function: 'DIGITAL_CURRENCY_DAILY', symbol: symbol, market: market, datatype: datatype)
  end

  def fx_daily(from_symbol:, to_symbol:, outputsize: nil, datatype: 'json')
    query(function: 'FX_DAILY', from_symbol: from_symbol, to_symbol: to_symbol, outputsize: outputsize, datatype: datatype)
  end

  def global_quote(symbol:, datatype: 'json')
    query(function: 'GLOBAL_QUOTE', symbol: symbol, datatype: datatype)
  end

  def time_series_daily_adjusted(symbol:, outputsize: nil, datatype: 'json')
    query(function: 'TIME_SERIES_DAILY_ADJUSTED', symbol: symbol, outputsize: outputsize, datatype: datatype)
  end

  def macd(symbol:, interval:, series_type:, fastperiod: nil, slowperiod: nil, signalperiod: nil, datatype: 'json')
    query(function: 'MACD', symbol: symbol, interval: interval, series_type: series_type, fastperiod: fastperiod, slowperiod: slowperiod, signalperiod: signalperiod, datatype: datatype)
  end


  def fx_intraday(from_symbol:, to_symbol:, interval:, outputsize: nil, datatype: 'json')
    query(function: 'FX_INTRADAY', from_symbol: from_symbol, to_symbol: to_symbol, interval: interval, outputsize: outputsize, datatype: datatype)
  end

  def digital_currency_monthly(symbol:, market:, datatype: 'json')
    query(function: 'DIGITAL_CURRENCY_MONTHLY', symbol: symbol, market: market, datatype: datatype)
  end

  def digital_currency_weekly(symbol:, market:, datatype: 'json')
    query(function: 'DIGITAL_CURRENCY_WEEKLY', symbol: symbol, market: market, datatype: datatype)
  end

  def time_series_intraday(symbol:, interval:, outputsize: nil, datatype: 'json')
    query(function: 'TIME_SERIES_INTRADAY', symbol: symbol, interval: interval, outputsize: outputsize, datatype: datatype)
  end

  def time_series_monthly(symbol:, datatype: 'json')
    query(function: 'TIME_SERIES_MONTHLY', symbol: symbol, datatype: datatype)
  end

  def time_series_weekly(symbol:, datatype: 'json')
    query(function: 'TIME_SERIES_WEEKLY', symbol: symbol, datatype: datatype)
  end

  def macd_ext(symbol:, interval:, series_type:, fastperiod: nil, slowperiod: nil, signalperiod: nil, matype: nil, datatype: 'json')
    query(function: 'MACDEXT', symbol: symbol, interval: interval, series_type: series_type, fastperiod: fastperiod, slowperiod: slowperiod, signalperiod: signalperiod, matype: matype, datatype: datatype)
  end

  def macd(symbol:, interval:, series_type:, time_period:, datatype: 'json')
    query(function: 'MACD', symbol: symbol, interval: interval, series_type: series_type, time_period: time_period, datatype: datatype)
  end

  def rsi(symbol:, interval:, time_period:, series_type:, datatype: 'json')
    query(function: 'RSI', symbol: symbol, interval: interval, time_period: time_period, series_type: series_type, datatype: datatype)
  end

  def fx_monthly(from_symbol:, to_symbol:, datatype: 'json')
    query(function: 'FX_MONTHLY', from_symbol: from_symbol, to_symbol: to_symbol, datatype: datatype)
  end

  def fx_weekly(from_symbol:, to_symbol:, datatype: 'json')
    query(function: 'FX_WEEKLY', from_symbol: from_symbol, to_symbol: to_symbol, datatype: datatype)
  end

  def mama(symbol:, interval:, series_type:, fastlimit:, slowlimit:, datatype: 'json')
    query(function: 'MAMA', symbol: symbol, interval: interval, series_type: series_type, fastlimit: fastlimit, slowlimit: slowlimit, datatype: datatype)
  end

  def mfi(symbol:, interval:, time_period:, datatype: 'json')
    query(function: 'MFI', symbol: symbol, interval: interval, time_period: time_period, datatype: datatype)
  end

  def midpoint(symbol:, interval:, time_period:, series_type:, datatype: 'json')
    query(function: 'MIDPOINT', symbol: symbol, interval: interval, time_period: time_period, series_type: series_type, datatype: datatype)
  end

  def midprice(symbol:, interval:, time_period:, datatype: 'json')
    query(function: 'MIDPRICE', symbol: symbol, interval: interval, time_period: time_period, datatype: datatype)
  end

  def minus_di(symbol:, interval:, time_period:, datatype: 'json')
    query(function: 'MINUS_DI', symbol: symbol, interval: interval, time_period: time_period, datatype: datatype)
  end

  def minus_dm(symbol:, interval:, time_period:, datatype: 'json')
    query(function: 'MINUS_DM', symbol: symbol, interval: interval, time_period: time_period, datatype: datatype)
  end

  def mom(symbol:, interval:, time_period:, series_type:, datatype: 'json')
    query(function: 'MOM', symbol: symbol, interval: interval, time_period: time_period, series_type: series_type, datatype: datatype)
  end

  def natr(symbol:, interval:, time_period:, datatype: 'json')
    query(function: 'NATR', symbol: symbol, interval: interval, time_period: time_period, datatype: datatype)
  end

  def obv(symbol:, interval:, datatype: 'json')
    query(function: 'OBV', symbol: symbol, interval: interval, datatype: datatype)
  end

  def overview(symbol:, datatype: 'json')
    query(function: 'OVERVIEW', symbol: symbol, datatype: datatype)
  end

  def plus_di(symbol:, interval:, time_period:, datatype: 'json')
    query(function: 'PLUS_DI', symbol: symbol, interval: interval, time_period: time_period, datatype: datatype)
  end

  def plus_dm(symbol:, interval:, time_period:, datatype: 'json')
    query(function: 'PLUS_DM', symbol: symbol, interval: interval, time_period: time_period, datatype: datatype)
  end

  def ppo(symbol:, interval:, series_type:, fastperiod:, slowperiod=nil:, matype=nil:, datatype: 'json')
    query(function: 'PPO', symbol: symbol, interval: interval, series_type: series_type, fastperiod: fastperiod, slowperiod: slowperiod, matype: matype, datatype: datatype)
  end

  def roc(symbol:, interval:, time_period:, series_type:, datatype: 'json')
    query(function: 'ROC', symbol: symbol, interval: interval, time_period: time_period, series_type: series_type, datatype: datatype)
  end

  def rocr(symbol:, interval:, time_period:, series_type:, datatype: 'json')
    query(function: 'ROCR', symbol: symbol, interval: interval, time_period: time_period, series_type: series_type, datatype: datatype)
  end

  def stoch(symbol:, interval:, fastkperiod=nil:, slowkperiod=nil:, slowdperiod=nil:, slowkmatype=nil:, slowdmatype=nil:, datatype: 'json')
    query(function: 'STOCH', symbol: symbol, interval: interval, fastkperiod: fastkperiod, slowkperiod: slowkperiod, slowdperiod: slowdperiod, slowkmatype: slowkmatype, slowdmatype: slowdmatype, datatype: datatype)
  end

  def sar(symbol:, interval:, acceleration:, maximum:, datatype: 'json')
    query(function: 'SAR', symbol: symbol, interval: interval, acceleration: acceleration, maximum: maximum, datatype: datatype)
  end

  def sma(symbol:, interval:, time_period:, series_type:, datatype: 'json')
    query(function: 'SMA', symbol: symbol, interval: interval, time_period: time_period, series_type: series_type, datatype: datatype)
  end

  def stochf(symbol:, interval:, fastkperiod: nil, fastdperiod: nil, fastdmatype: nil, datatype: 'json')
    query(function: 'STOCHF', symbol: symbol, interval: interval, fastkperiod: fastkperiod, fastdperiod: fastdperiod, fastdmatype: fastdmatype, datatype: datatype)
  end

  def t3(symbol:, interval:, time_period:, series_type:, datatype: 'json')
    query(function: 'T3', symbol: symbol, interval: interval, time_period: time_period, series_type: series_type, datatype: datatype)
  end

  def tema(symbol:, interval:, time_period:, series_type:, datatype: 'json')
    query(function: 'TEMA', symbol: symbol, interval: interval, time_period: time_period, series_type: series_type, datatype: datatype)
  end

  def time_series_monthly_adjusted(symbol:, datatype: 'json')
    query(function: 'TIME_SERIES_MONTHLY_ADJUSTED', symbol: symbol, datatype: datatype)
  end

  def time_series_weekly_adjusted(symbol:, datatype: 'json')
    query(function: 'TIME_SERIES_WEEKLY_ADJUSTED', symbol: symbol, datatype: datatype)
  end

  def trange(symbol:, interval:, datatype: 'json')
    query(function: 'TRANGE', symbol: symbol, interval: interval, datatype: datatype)
  end

  def trima(symbol:, interval:, time_period:, series_type:, datatype: 'json')
    query(function: 'TRIMA', symbol: symbol, interval: interval, time_period: time_period, series_type: series_type, datatype: datatype)
  end

  def trix(symbol:, interval:, time_period:, series_type:, datatype: 'json')
    query(function: 'TRIX', symbol: symbol, interval: interval, time_period: time_period, series_type: series_type, datatype: datatype)
  end

  def ultosc(symbol:, interval:, timeperiod1: nil, timeperiod2: nil, timeperiod3: nil, datatype: 'json')
    query(function: 'ULTOSC', symbol: symbol, interval: interval, timeperiod1: timeperiod1, timeperiod2: timeperiod2, timeperiod3: timeperiod3, datatype: datatype)
  end

  def vwap(symbol:, interval:, datatype: 'json')
    query(function: 'VWAP', symbol: symbol, interval: interval, datatype: datatype)
  end

  def willr(symbol:, interval:, time_period:, datatype: 'json')
    query(function: 'WILLR', symbol: symbol, interval: interval, time_period: time_period, datatype: datatype)
  end

  def wma(symbol:, interval:, time_period:, series_type:, datatype: 'json')
    query(function: 'WMA', symbol: symbol, interval: interval, time_period: time_period, series_type: series_type, datatype: datatype)
  end
end
