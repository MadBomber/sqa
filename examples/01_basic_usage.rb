#!/usr/bin/env ruby
# frozen_string_literal: true

# 01_basic_usage.rb
#
# The starting point for the SQA (Simple Qualitative Analysis) core library.
# It walks through the everyday building blocks you will reach for first:
#
#   1. Setup & configuration
#   2. Technical indicators (SMA, EMA, RSI)
#   3. Portfolio management (buy / sell / value / summary)
#   4. Working with SQA::DataFrame
#   5. Loading real market data and running a backtest
#
# Run it (either works):
#   ./examples/01_basic_usage.rb
#   bundle exec ruby examples/01_basic_usage.rb
#
# Sections 1–4 run fully offline. Section 5 loads AAPL from ~/sqa_data when the
# cached data is present, otherwise it fetches from Alpha Vantage (which needs
# the AV_API_KEY environment variable). If no data is available it prints
# guidance and skips — the rest of the example still runs.
#
# NOTE: SQA is an educational tool for learning technical analysis, NOT
# production trading software. Do not make real financial decisions with it.

# Use THIS checkout's lib/ (and the local sqa-tai) so the example always runs
# against the local source, even when launched directly
# (./examples/01_basic_usage.rb) rather than through `bundle exec`. Otherwise
# `require 'sqa'` could load a stale installed sqa gem.
require_relative 'local_libs'
require 'sqa'

# ---------------------------------------------------------------------------
# Small output helpers (kept tiny so each is trivial to reason about).
# ---------------------------------------------------------------------------

def heading(title)
  puts "\n#{'=' * 68}"
  puts title
  puts '=' * 68
end

# A deterministic, oldest-first price series so the example is reproducible.
# TA-Lib (and therefore SQAI) expects arrays in oldest-first order: index 0 is
# the oldest observation, the last index is the most recent.
def sample_prices(count = 60, start: 100.0)
  (0...count).map { |i| (start + (i * 0.35) + (Math.sin(i / 4.0) * 6)).round(2) }
end

# ===========================================================================
# 1. Setup & configuration
# ===========================================================================
heading('1. Setup & configuration')

# SQA.init loads configuration (defaults < env vars < config file) and prepares
# the library. Call it once before doing anything else.
SQA.init

puts <<~SETUP
  SQA version : #{SQA::VERSION}
  Data dir    : #{SQA.data_dir}
  (Cached <ticker>.csv / <ticker>.json files live in the data dir. When a
   Stock isn't cached there, SQA fetches it from Alpha Vantage / Yahoo.)
SETUP

# ===========================================================================
# 2. Technical indicators
# ===========================================================================
heading('2. Technical indicators (SMA, EMA, RSI)')

# All indicator math lives in the sqa-tai gem and is reached through SQAI
# (a shortcut for SQA::TAI). Indicators operate on plain Ruby Arrays of
# Floats — extract a price array, then hand it to an indicator.
prices = sample_prices

begin
  sma = SQAI.sma(prices, period: 20)   # Simple Moving Average
  ema = SQAI.ema(prices, period: 20)   # Exponential Moving Average
  rsi = SQAI.rsi(prices, period: 14)   # Relative Strength Index (0–100)

  puts <<~IND
    #{prices.length} prices, latest = #{prices.last}

    SMA(20) latest : #{sma.last.round(2)}
    EMA(20) latest : #{ema.last.round(2)}
    RSI(14) latest : #{rsi.last.round(2)}   (>70 overbought, <30 oversold)
  IND
rescue StandardError => e
  # SQAI raises if the TA-Lib C library isn't installed (brew install ta-lib).
  puts "Skipping indicators — #{e.message}"
end

# ===========================================================================
# 3. Portfolio management
# ===========================================================================
heading('3. Portfolio management')

# SQA::Portfolio tracks cash, positions, and trade history with P&L. It needs
# no market data — it just records the trades you make.
portfolio = SQA::Portfolio.new(initial_cash: 10_000.0, commission: 1.0)

portfolio.buy('AAPL', shares: 10, price: 150.0)
portfolio.sell('AAPL', shares: 4, price: 165.0)   # take some profit

# Pass the latest prices to value/summary so unrealized P&L can be computed.
current_prices = { 'AAPL' => 170.0 }
summary = portfolio.summary(current_prices)

puts <<~PORT
  Bought 10 AAPL @ $150, sold 4 @ $165, now marked at $170.

  Cash on hand   : $#{summary[:current_cash]}
  Open positions : #{summary[:positions_count]}
  Total value    : $#{summary[:total_value]}
  Profit / loss  : $#{summary[:profit_loss]} (#{summary[:profit_loss_percent]}%)
  Trades         : #{summary[:total_trades]} (#{summary[:buy_trades]} buy, #{summary[:sell_trades]} sell)
PORT

# ===========================================================================
# 4. Working with SQA::DataFrame
# ===========================================================================
heading('4. Working with SQA::DataFrame')

# SQA::DataFrame wraps a Polars DataFrame (Rust-backed, fast). You will usually
# get one from a Stock, but you can also build one directly — here from an
# array of hashes. Prefer column operations over row iteration.
df = SQA::DataFrame.from_aofh(
  [
    { timestamp: '2024-01-02', adj_close_price: 100.0, volume: 1_000 },
    { timestamp: '2024-01-03', adj_close_price: 102.5, volume: 1_400 },
    { timestamp: '2024-01-04', adj_close_price: 101.0, volume: 1_100 },
    { timestamp: '2024-01-05', adj_close_price: 104.0, volume: 1_800 }
  ]
)

# df.data is the underlying Polars::DataFrame; column access returns a series
# you can turn into a Ruby Array with .to_a.
puts <<~DF
  Rows    : #{df.size}
  Columns : #{df.data.columns.join(', ')}
  Closes  : #{df['adj_close_price'].to_a.inspect}
DF

# ===========================================================================
# 5. Real market data + a backtest
# ===========================================================================
heading('5. Real market data + a backtest')

begin
  # Loads ~/sqa_data/aapl.{csv,json} if cached, else fetches it.
  stock = SQA::Stock.new(ticker: 'AAPL')
  closes = stock.df['adj_close_price'].to_a

  puts <<~STOCK
    Loaded #{stock.ticker.upcase}: #{stock.df.data.height} rows,
    columns: #{stock.df.data.columns.join(', ')}
    price range: $#{closes.min.round(2)} – $#{closes.max.round(2)}
  STOCK

  # A strategy is anything Backtest can call for a signal. The simplest form is
  # a lambda: it receives the price history up to "today" and returns one of
  # :buy, :sell, or :hold. (You can also write a class with a `trade(vector)`
  # method — see the other examples in this directory.)
  rsi_strategy = lambda do |history|
    next :hold if history.length < 15

    rsi = SQAI.rsi(history, period: 14).last
    if    rsi < 30 then :buy    # oversold  -> enter
    elsif rsi > 70 then :sell   # overbought -> exit
    else  :hold
    end
  end

  results = SQA::Backtest.new(
    stock: stock,
    strategy: rsi_strategy,
    initial_capital: 10_000.0,
    commission: 1.0,
    start_date: '2020-01-01',
    end_date: '2023-12-31'
  ).run

  puts "\n#{results.summary}"
rescue StandardError => e
  puts <<~MISS
    Could not load market data (#{e.class}: #{e.message}).

    To run this section, either:
      • place cached data at #{SQA.data_dir}/aapl.csv and aapl.json, or
      • set AV_API_KEY to a valid Alpha Vantage key and re-run.
  MISS
end

heading('Done')
puts 'Next: explore 02_strategy_generator.rb, 03_genetic_programming.rb, and the others.'
