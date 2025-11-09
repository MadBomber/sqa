#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'
require 'json'

# Add SQA lib to load path
$LOAD_PATH.unshift(File.expand_path('../../lib', __dir__))

require 'sqa'

# Initialize SQA
SQA.init

# Configure Sinatra
set :port, 4567
set :bind, '0.0.0.0'
set :public_folder, File.dirname(__FILE__) + '/public'
set :views, File.dirname(__FILE__) + '/views'

# Enable sessions for flash messages
enable :sessions

# Helpers
helpers do
  def format_percent(value)
    sprintf("%.2f%%", value)
  end

  def format_currency(value)
    sprintf("$%.2f", value)
  end

  def format_number(value)
    value.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end

# Routes

# Home / Dashboard
get '/' do
  erb :index
end

# Dashboard for specific ticker
get '/dashboard/:ticker' do
  ticker = params[:ticker].upcase

  begin
    @stock = SQA::Stock.new(ticker: ticker)
    @ticker = ticker
    erb :dashboard
  rescue => e
    @error = "Failed to load data for #{ticker}: #{e.message}"
    erb :error
  end
end

# Analysis page
get '/analyze/:ticker' do
  ticker = params[:ticker].upcase

  begin
    @stock = SQA::Stock.new(ticker: ticker)
    @ticker = ticker
    erb :analyze
  rescue => e
    @error = "Failed to load data for #{ticker}: #{e.message}"
    erb :error
  end
end

# Backtest page
get '/backtest/:ticker' do
  ticker = params[:ticker].upcase

  begin
    @stock = SQA::Stock.new(ticker: ticker)
    @ticker = ticker
    erb :backtest
  rescue => e
    @error = "Failed to load data for #{ticker}: #{e.message}"
    erb :error
  end
end

# Portfolio optimizer
get '/portfolio' do
  erb :portfolio
end

# API Endpoints

# Get stock data
get '/api/stock/:ticker' do
  content_type :json

  ticker = params[:ticker].upcase

  begin
    stock = SQA::Stock.new(ticker: ticker)
    df = stock.df

    # Get price data
    dates = df["date"].to_a.map(&:to_s)
    opens = df["open_price"].to_a
    highs = df["high_price"].to_a
    lows = df["low_price"].to_a
    closes = df["adj_close_price"].to_a
    volumes = df["volume"].to_a

    # Calculate basic stats
    current_price = closes.last
    prev_price = closes[-2]
    change = current_price - prev_price
    change_pct = (change / prev_price) * 100

    {
      ticker: ticker,
      current_price: current_price,
      change: change,
      change_percent: change_pct,
      high_52w: closes.last(252).max,
      low_52w: closes.last(252).min,
      dates: dates,
      open: opens,
      high: highs,
      low: lows,
      close: closes,
      volume: volumes
    }.to_json
  rescue => e
    status 500
    { error: e.message }.to_json
  end
end

# Get technical indicators
get '/api/indicators/:ticker' do
  content_type :json

  ticker = params[:ticker].upcase

  begin
    stock = SQA::Stock.new(ticker: ticker)
    df = stock.df

    prices = df["adj_close_price"].to_a
    highs = df["high_price"].to_a
    lows = df["low_price"].to_a
    dates = df["date"].to_a.map(&:to_s)

    # Calculate indicators
    rsi = SQAI.rsi(prices, period: 14)
    macd_result = SQAI.macd(prices)
    bb_result = SQAI.bbands(prices)
    sma_20 = SQAI.sma(prices, period: 20)
    sma_50 = SQAI.sma(prices, period: 50)
    ema_20 = SQAI.ema(prices, period: 20)

    {
      dates: dates,
      rsi: rsi,
      macd: macd_result[0],        # MACD line
      macd_signal: macd_result[1], # Signal line
      macd_hist: macd_result[2],   # Histogram
      bb_upper: bb_result[0],
      bb_middle: bb_result[1],
      bb_lower: bb_result[2],
      sma_20: sma_20,
      sma_50: sma_50,
      ema_20: ema_20
    }.to_json
  rescue => e
    status 500
    { error: e.message }.to_json
  end
end

# Run backtest
post '/api/backtest/:ticker' do
  content_type :json

  ticker = params[:ticker].upcase
  strategy_name = params[:strategy] || 'RSI'

  begin
    stock = SQA::Stock.new(ticker: ticker)

    # Resolve strategy
    strategy = case strategy_name.upcase
               when 'RSI' then SQA::Strategy::RSI
               when 'SMA' then SQA::Strategy::SMA
               when 'EMA' then SQA::Strategy::EMA
               when 'MACD' then SQA::Strategy::MACD
               when 'BOLLINGERBANDS' then SQA::Strategy::BollingerBands
               when 'KBS' then SQA::Strategy::KBS
               else SQA::Strategy::RSI
               end

    # Run backtest
    backtest = SQA::Backtest.new(
      stock: stock,
      strategy: strategy,
      initial_capital: 10_000.0,
      commission: 1.0
    )

    results = backtest.run

    {
      total_return: results.total_return,
      annualized_return: results.annualized_return,
      sharpe_ratio: results.sharpe_ratio,
      max_drawdown: results.max_drawdown,
      win_rate: results.win_rate,
      total_trades: results.total_trades,
      profit_factor: results.profit_factor,
      avg_win: results.avg_win,
      avg_loss: results.avg_loss
    }.to_json
  rescue => e
    status 500
    { error: e.message }.to_json
  end
end

# Run market analysis
get '/api/analyze/:ticker' do
  content_type :json

  ticker = params[:ticker].upcase

  begin
    stock = SQA::Stock.new(ticker: ticker)
    prices = stock.df["adj_close_price"].to_a

    # Market regime
    regime = SQA::MarketRegime.detect(stock)

    # Seasonal analysis
    seasonal = SQA::SeasonalAnalyzer.analyze(stock)

    # FPOP analysis
    fpop_data = SQA::FPOP.fpl_analysis(prices, fpop: 10)
    recent_fpop = fpop_data.last(10).map do |f|
      {
        direction: f[:direction],
        magnitude: f[:magnitude],
        risk: f[:risk],
        interpretation: f[:interpretation]
      }
    end

    # Risk metrics
    returns = prices.each_cons(2).map { |a, b| (b - a) / a }
    var_95 = SQA::RiskManager.var(returns, confidence: 0.95)
    sharpe = SQA::RiskManager.sharpe_ratio(returns)
    max_dd = SQA::RiskManager.max_drawdown(prices)

    {
      regime: {
        type: regime[:type],
        volatility: regime[:volatility],
        strength: regime[:strength],
        trend: regime[:trend]
      },
      seasonal: {
        best_months: seasonal[:best_months],
        worst_months: seasonal[:worst_months],
        best_quarters: seasonal[:best_quarters],
        has_pattern: seasonal[:has_seasonal_pattern]
      },
      fpop: recent_fpop,
      risk: {
        var_95: var_95,
        sharpe_ratio: sharpe,
        max_drawdown: max_dd[:max_drawdown]
      }
    }.to_json
  rescue => e
    status 500
    { error: e.message }.to_json
  end
end

# Compare strategies
post '/api/compare/:ticker' do
  content_type :json

  ticker = params[:ticker].upcase

  begin
    stock = SQA::Stock.new(ticker: ticker)

    strategies = {
      'RSI' => SQA::Strategy::RSI,
      'SMA' => SQA::Strategy::SMA,
      'EMA' => SQA::Strategy::EMA,
      'MACD' => SQA::Strategy::MACD,
      'BollingerBands' => SQA::Strategy::BollingerBands
    }

    results = strategies.map do |name, strategy_class|
      backtest = SQA::Backtest.new(
        stock: stock,
        strategy: strategy_class,
        initial_capital: 10_000.0,
        commission: 1.0
      )

      result = backtest.run

      {
        strategy: name,
        return: result.total_return,
        sharpe: result.sharpe_ratio,
        drawdown: result.max_drawdown,
        win_rate: result.win_rate,
        trades: result.total_trades
      }
    rescue => e
      nil
    end.compact

    results.sort_by! { |r| -r[:return] }
    results.to_json
  rescue => e
    status 500
    { error: e.message }.to_json
  end
end

# Start server
if __FILE__ == $0
  puts "=" * 60
  puts "SQA Web Application"
  puts "=" * 60
  puts "Starting server on http://localhost:4567"
  puts "Press Ctrl+C to stop"
  puts "=" * 60
end
