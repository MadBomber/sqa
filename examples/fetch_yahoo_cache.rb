#!/usr/bin/env ruby
# frozen_string_literal: true

# fetch_yahoo_cache.rb
#
# Fetches Yahoo Finance fundamentals + 3-year price history for one or more
# tickers using a REAL Chrome browser, and writes each ticker's raw
# {"summary" => ..., "chart" => ...} JSON to examples/.yahoo_cache/<ticker>.json
# for 09_dividend_quality_screener.rb to read offline.
#
# Why a real browser instead of plain HTTP (curl/Faraday)? Yahoo's
# quoteSummary/chart APIs require a cookie+crumb handshake, and Yahoo's
# rate limiting on that handshake is apparently tied to the network path,
# not just the requesting IP as a whole -- a curl/Ruby HTTP client can get
# 429 Too Many Requests from the exact same endpoint a real Chrome browser
# gets 200 from. Driving actual Chrome via CDP (the `ferrum` gem) sidesteps
# that by making the same requests a real browser session would.
#
# Usage (run directly with `ruby`, NOT `bundle exec` -- see note below):
#   ./examples/fetch_yahoo_cache.rb                  # the screener's default portfolio
#   ./examples/fetch_yahoo_cache.rb AAPL KO JNJ       # specific tickers
#   ./examples/fetch_yahoo_cache.rb --headful AAPL    # show the browser window (debugging)
#
# Requires the `ferrum` gem and a local Chrome/Chromium install:
#   gem install ferrum
#
# Deliberately run with plain `ruby`, not `bundle exec ruby`: ferrum drives a
# real browser purely to work around Yahoo's network-level rate limiting on
# this one utility script, which has nothing to do with sqa's own dependency
# graph, so it isn't declared in sqa.gemspec. Install it into your system/
# rbenv gemset directly instead.
#
# NOTE: this scrapes Yahoo's unofficial internal API. Be a reasonable user of
# it -- this script fetches a handful of tickers, not thousands.

begin
  require 'ferrum'
rescue LoadError
  warn "This script needs the ferrum gem: gem install ferrum"
  warn '(Run it with plain `ruby`, not `bundle exec ruby` -- see the file header.)'
  exit 1
end

require 'json'
require 'fileutils'

DEFAULT_TICKERS = %w[F T PFE XOM ET VZ CVX AGNC NLY PSEC].freeze
CACHE_DIR = File.expand_path('.yahoo_cache', __dir__)
FETCH_TIMEOUT_SECONDS = 20
REQUEST_DELAY_SECONDS = 0.5

# Runs inside the browser page via Ferrum::Frame::Runtime#evaluate_async.
# arguments[0] is the ticker (passed in from Ruby); the last argument is an
# implicit callback ferrum appends -- calling it resolves evaluate_async's
# return value back in Ruby. Fetches run in-page, so they carry the real
# browser session's cookies automatically (same-origin credentials).
FETCH_SCRIPT = <<~JS
  (async () => {
    const done = arguments[arguments.length - 1];
    const ticker = arguments[0];
    try {
      const crumbResp = await fetch('https://query1.finance.yahoo.com/v1/test/getcrumb', { credentials: 'include' });
      if (!crumbResp.ok) throw new Error(`getcrumb HTTP ${crumbResp.status}`);
      const crumb = await crumbResp.text();

      const modules = 'summaryDetail,defaultKeyStatistics,financialData,price';
      const qsResp = await fetch(
        `https://query1.finance.yahoo.com/v10/finance/quoteSummary/${ticker}?modules=${modules}&formatted=false&crumb=${encodeURIComponent(crumb)}`,
        { credentials: 'include' }
      );
      const qs = await qsResp.json();
      if (qs?.quoteSummary?.error) throw new Error(qs.quoteSummary.error.description);

      const chartResp = await fetch(
        `https://query1.finance.yahoo.com/v8/finance/chart/${ticker}?interval=1d&range=3y&crumb=${encodeURIComponent(crumb)}`,
        { credentials: 'include' }
      );
      const chart = await chartResp.json();
      if (chart?.chart?.error) throw new Error(chart.chart.error.description);

      done({ ok: true, summary: qs.quoteSummary.result[0], chart: chart.chart.result[0] });
    } catch (e) {
      done({ ok: false, error: String(e) });
    }
  })();
JS

def fetch_ticker(page, ticker)
  page.evaluate_async(FETCH_SCRIPT, FETCH_TIMEOUT_SECONDS, ticker)
end

def write_cache(ticker, result)
  path = File.join(CACHE_DIR, "#{ticker.downcase}.json")
  File.write(path, JSON.generate({ 'summary' => result['summary'], 'chart' => result['chart'] }))
  points = result.dig('chart', 'timestamp')&.size || 0
  puts "  #{ticker}: cached (#{points} price points) -> #{path}"
end

headful = ARGV.delete('--headful')
tickers = ARGV.empty? ? DEFAULT_TICKERS : ARGV.map(&:upcase)

FileUtils.mkdir_p(CACHE_DIR)

puts "Launching Chrome (#{headful ? 'headful' : 'headless'})..."
browser = Ferrum::Browser.new(headless: !headful, timeout: FETCH_TIMEOUT_SECONDS + 10)

begin
  page = browser.create_page

  puts 'Establishing a Yahoo Finance session...'
  page.go_to('https://finance.yahoo.com/')
  sleep 2 # let the SPA finish setting cookies

  puts "Fetching #{tickers.size} ticker(s): #{tickers.join(', ')}"
  failures = []
  tickers.each_with_index do |ticker, i|
    sleep REQUEST_DELAY_SECONDS if i.positive?

    result = fetch_ticker(page, ticker)
    if result['ok']
      write_cache(ticker, result)
    else
      failures << ticker
      puts "  #{ticker}: FAILED - #{result['error']}"
    end
  end

  puts "\nDone. #{tickers.size - failures.size}/#{tickers.size} tickers cached in #{CACHE_DIR}"
  puts "Failed: #{failures.join(', ')}" unless failures.empty?
ensure
  browser.quit
end
