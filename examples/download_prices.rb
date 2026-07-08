#!/usr/bin/env ruby
# frozen_string_literal: true

# download_prices.rb
#
# Download daily (1d) historical price CSVs for one or more ticker symbols,
# with incremental updates:
#
#   * If no CSV exists yet for a symbol, download its MAXIMUM available
#     history (Yahoo's `range=max`).
#   * If a CSV already exists, read the last date in the file and download
#     only the rows dated AFTER that through today, appending them (skipping
#     any duplicate dates).
#
# Data source: Yahoo Finance's chart API (query1.finance.yahoo.com/v8/finance/chart),
# the same data `sqa`'s SQA::DataFrame::YahooFinance uses. NOT stockquote.io:
# that site's robots.txt explicitly Disallows its /download_csv backend route
# to automated agents, and it's just a Yahoo frontend anyway. We go to the
# real source, which carries no such directive.
#
# Why a real browser (ferrum) instead of plain HTTP? Yahoo rate-limits its
# API by network path, not just source IP -- a curl/Net::HTTP client gets
# 429 Too Many Requests from the same endpoint a real Chrome browser gets
# 200 from. Driving actual headless Chrome via CDP sidesteps that.
#
# Usage (run with plain `ruby`, NOT `bundle exec` -- ferrum isn't a sqa
# gemspec dependency; install it into your gemset with `gem install ferrum`):
#
#   ./examples/download_prices.rb AAPL MSFT KO
#   ./examples/download_prices.rb --dir ~/prices AAPL
#   ./examples/download_prices.rb --headful AAPL         # watch the browser
#
# Output CSVs are OLDEST-FIRST (ascending), ISO dates, columns:
#   Date,Open,High,Low,Close,Adj Close,Volume
# (ascending order is what TA-Lib / sqa expect; ISO dates sort correctly.)
#
# NOTE: educational tool. Yahoo's API is unofficial and can change or break.

begin
  require 'ferrum'
rescue LoadError
  warn 'This script needs the ferrum gem: gem install ferrum'
  warn '(Run it with plain `ruby`, not `bundle exec ruby`.)'
  exit 1
end

require 'json'
require 'date'
require 'time'
require 'fileutils'

CSV_HEADER = 'Date,Open,High,Low,Close,Adj Close,Volume'
FETCH_TIMEOUT_SECONDS = 30
REQUEST_DELAY_SECONDS = 0.5

# In-page fetch of Yahoo's chart JSON. arguments[0] is the full chart URL
# (built in Ruby), the last argument is ferrum's implicit resolve callback.
# Runs same-origin in the browser so it carries the session cookies.
FETCH_SCRIPT = <<~JS
  (async () => {
    const done = arguments[arguments.length - 1];
    const url = arguments[0];
    try {
      const resp = await fetch(url, { credentials: 'include' });
      if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
      const j = await resp.json();
      if (j?.chart?.error) throw new Error(j.chart.error.description);
      done({ ok: true, result: j.chart.result[0] });
    } catch (e) {
      done({ ok: false, error: String(e) });
    }
  })();
JS

# ---------------------------------------------------------------------------
# Pure helpers (no browser/IO) -- easy to test in isolation
# ---------------------------------------------------------------------------

# Turn a Yahoo chart `result` object into oldest-first CSV row arrays:
# [iso_date, open, high, low, close, adj_close, volume]. Rows with any null
# OHLC value (Yahoo occasionally emits them) are dropped.
def rows_from_chart(result)
  timestamps = result['timestamp'] || []
  quote = result.dig('indicators', 'quote', 0) || {}
  adj = result.dig('indicators', 'adjclose', 0, 'adjclose') || []
  opens = quote['open'] || []
  highs = quote['high'] || []
  lows = quote['low'] || []
  closes = quote['close'] || []
  volumes = quote['volume'] || []

  timestamps.each_index.filter_map do |i|
    o = opens[i]; h = highs[i]; l = lows[i]; c = closes[i]
    next if [o, h, l, c].any?(&:nil?)

    a = adj[i] || c
    v = volumes[i] || 0
    date = Time.at(timestamps[i]).utc.strftime('%Y-%m-%d')
    [date, r4(o), r4(h), r4(l), r4(c), r4(a), v.to_i]
  end
end

def r4(value)
  value.to_f.round(4)
end

# Read the most recent (last) date from an existing ascending CSV, or nil if
# the file is missing/empty/header-only.
def last_date_in_csv(path)
  return nil unless File.exist?(path)

  last = nil
  File.foreach(path) do |line|
    line = line.strip
    next if line.empty? || line.start_with?('Date,')

    last = line
  end
  return nil if last.nil?

  Date.parse(last.split(',', 2).first)
rescue ArgumentError
  nil
end

# Set of ISO date strings already present in an existing CSV (for dedup on
# append).
def existing_dates(path)
  return {} unless File.exist?(path)

  dates = {}
  File.foreach(path) do |line|
    field = line.split(',', 2).first
    dates[field] = true if field && field.match?(/\A\d{4}-\d{2}-\d{2}\z/)
  end
  dates
end

# Build the chart URL. Always uses an explicit period1..period2 window with
# interval=1d. For full history `since` is nil, so period1 is epoch 0 (1970)
# -- Yahoo returns from the security's actual first trading day. (We do NOT
# use range=max: Yahoo silently downsamples range=max to MONTHLY granularity
# regardless of interval=1d; an explicit wide period window stays daily.)
def chart_url(ticker, crumb, since: nil)
  base = "https://query1.finance.yahoo.com/v8/finance/chart/#{ticker}?interval=1d"
  base += "&crumb=#{crumb}" unless crumb.nil? || crumb.empty?
  period1 = since ? since.to_time.utc.to_i : 0
  period2 = Time.now.to_i + 86_400 # pad a day so today is always included
  "#{base}&period1=#{period1}&period2=#{period2}"
end

# ---------------------------------------------------------------------------
# Browser-backed fetch
# ---------------------------------------------------------------------------

def fetch_crumb(page)
  result = page.evaluate_async(<<~JS, FETCH_TIMEOUT_SECONDS)
    (async () => {
      const done = arguments[arguments.length - 1];
      try {
        const r = await fetch('https://query1.finance.yahoo.com/v1/test/getcrumb', { credentials: 'include' });
        done(await r.text());
      } catch (e) { done(''); }
    })();
  JS
  result.to_s.strip
end

def fetch_chart(page, url)
  page.evaluate_async(FETCH_SCRIPT, FETCH_TIMEOUT_SECONDS, url)
end

# ---------------------------------------------------------------------------
# Per-ticker processing
# ---------------------------------------------------------------------------

def process_ticker(page, crumb, ticker, data_dir)
  path = File.join(data_dir, "#{ticker.upcase}.csv")
  last = last_date_in_csv(path)

  if last
    since = last + 1
    if since > Date.today
      puts "  #{ticker}: already current (last date #{last})"
      return
    end
    puts "  #{ticker}: updating from #{since} ..."
  else
    since = nil
    puts "  #{ticker}: no existing file, downloading full history ..."
  end

  response = fetch_chart(page, chart_url(ticker.upcase, crumb, since: since))
  unless response['ok']
    puts "  #{ticker}: FAILED - #{response['error']}"
    return
  end

  rows = rows_from_chart(response['result'])
  if last
    seen = existing_dates(path)
    rows.reject! { |row| seen[row.first] }
    if rows.empty?
      puts "  #{ticker}: no new rows"
      return
    end
    File.open(path, 'a') { |f| rows.each { |row| f.puts(row.join(',')) } }
    puts "  #{ticker}: appended #{rows.size} new row(s) -> #{path}"
  else
    File.open(path, 'w') do |f|
      f.puts CSV_HEADER
      rows.each { |row| f.puts(row.join(',')) }
    end
    puts "  #{ticker}: wrote #{rows.size} row(s) (#{rows.first&.first}..#{rows.last&.first}) -> #{path}"
  end
end

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args(argv)
  argv = argv.dup
  headful = !argv.delete('--headful').nil?
  data_dir = '.'
  if (i = argv.index('--dir'))
    data_dir = argv[i + 1] or abort 'Error: --dir requires a path'
    argv.delete_at(i + 1)
    argv.delete_at(i)
  end
  tickers = argv.map(&:upcase)
  abort "Usage: #{$PROGRAM_NAME} [--dir PATH] [--headful] SYMBOL [SYMBOL ...]" if tickers.empty?

  [tickers, File.expand_path(data_dir), headful]
end

def main(argv)
  tickers, data_dir, headful = parse_args(argv)
  FileUtils.mkdir_p(data_dir)

  puts "Data directory: #{data_dir}"
  puts "Launching Chrome (#{headful ? 'headful' : 'headless'})..."
  browser = Ferrum::Browser.new(headless: !headful, timeout: FETCH_TIMEOUT_SECONDS + 10)

  begin
    page = browser.create_page
    puts 'Establishing a Yahoo Finance session...'
    page.go_to('https://finance.yahoo.com/')
    sleep 2
    crumb = fetch_crumb(page)

    puts "Processing #{tickers.size} ticker(s): #{tickers.join(', ')}"
    tickers.each_with_index do |ticker, i|
      sleep REQUEST_DELAY_SECONDS if i.positive?
      process_ticker(page, crumb, ticker, data_dir)
    end
  ensure
    browser.quit
  end
end

main(ARGV) if $PROGRAM_NAME == __FILE__
