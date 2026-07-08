#!/usr/bin/env ruby
# frozen_string_literal: true

# 09_dividend_quality_screener.rb
#
# Screens a portfolio of dividend-paying tickers for QUALITY (is the dividend
# sustainable?), RISK (leverage, volatility, drawdown), and YIELD, then ranks
# them by a weighted composite score: highest quality, lowest risk, highest
# yield.
#
# Data source: Yahoo Finance's unofficial quoteSummary and chart JSON APIs,
# fetched directly (bypassing SQA::Stock, which only pulls fundamentals from
# Alpha Vantage). No API key and no official rate limit, which sidesteps
# Alpha Vantage's free-tier 25-requests/day cap entirely — but this is an
# unauthenticated scrape of Yahoo's internal API, so it can break if Yahoo
# changes their site. It requires curl (for the cookie/crumb handshake) and
# the faraday gem (already a dependency of sqa).
#
# Fundamentals covered: dividend yield, payout ratio, profit margin, ROE,
# earnings growth, beta, and debt-to-equity — a superset of what Alpha
# Vantage's OVERVIEW endpoint provides (it has no debt-to-equity or
# leverage data at all). Price history comes from Yahoo's split/dividend-
# adjusted close series, avoiding the "is adj_close_price actually split-
# adjusted?" caveat that applies to sqa's cached Alpha Vantage CSVs.
#
# Run it (either works):
#   ./examples/09_dividend_quality_screener.rb
#   ./examples/09_dividend_quality_screener.rb AAPL KO JNJ
#   bundle exec ruby examples/09_dividend_quality_screener.rb
#
# Set YF_COOKIE / YF_CRUMB to bypass the curl cookie/crumb acquisition
# (useful if you already have a browser session, or curl gets rate-limited).
#
# If curl/Ruby's network path gets IP-rate-limited by Yahoo independently of
# a real browser's (this happens), run fetch_yahoo_cache.rb first -- it uses
# an actual headless Chrome (via the `ferrum` gem) to fetch and cache data
# for you, which this script then reads with zero network calls of its own:
#   ruby examples/fetch_yahoo_cache.rb F T PFE XOM ET VZ CVX AGNC NLY PSEC
#
# NOTE: SQA is an educational tool for learning technical analysis, NOT
# production trading software. Do not make real financial decisions with it.

require_relative 'local_libs'
require 'sqa'
require 'faraday'
require 'json'
require 'tempfile'
require 'shellwords'

# ---------------------------------------------------------------------------
# Minimal Yahoo Finance client: cookie/crumb handshake + quoteSummary/chart.
# Self-contained here rather than added to sqa itself -- this is a scrape of
# an undocumented API, not something the core gem should depend on.
# ---------------------------------------------------------------------------
module YahooFinanceClient
  BROWSER_UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) ' \
               'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
  BASE_HEADERS = {
    'User-Agent' => BROWSER_UA,
    'Accept' => 'application/json, text/plain, */*',
    'Accept-Language' => 'en-US,en;q=0.9',
    'Referer' => 'https://finance.yahoo.com',
    'Origin' => 'https://finance.yahoo.com'
  }.freeze
  COOKIE_TTL = 1_800 # 30 minutes

  class << self
    attr_accessor :cookie, :crumb, :auth_at
  end

  def self.cookie_and_crumb
    return [ENV['YF_COOKIE'], ENV['YF_CRUMB']] if ENV['YF_COOKIE'] && ENV['YF_CRUMB']

    stale = auth_at.nil? || (Time.now.to_i - auth_at) > COOKIE_TTL
    if stale
      self.cookie, self.crumb = acquire_cookie_and_crumb
      self.auth_at = Time.now.to_i
    end
    [cookie, crumb]
  end

  # Uses curl for the cookie/crumb handshake -- curl's native cookie jar
  # handles redirects/SameSite reliably in a way plain Net::HTTP does not.
  def self.acquire_cookie_and_crumb
    cookie_file = Tempfile.new('sqa_yf_')
    cookie_path = cookie_file.path
    cookie_file.close

    `curl -s -L -c #{cookie_path.shellescape} -H #{"User-Agent: #{BROWSER_UA}".shellescape} \
      -H "Accept: text/html" "https://finance.yahoo.com/" -o /dev/null 2>&1`

    crumb = `curl -s -b #{cookie_path.shellescape} -H #{"User-Agent: #{BROWSER_UA}".shellescape} \
      -H "Referer: https://finance.yahoo.com" \
      "https://query2.finance.yahoo.com/v1/test/getcrumb" 2>&1`.strip

    if crumb.empty? || crumb.include?('Too Many') || crumb.length > 60
      raise "Failed to obtain Yahoo Finance crumb: #{crumb}"
    end

    lines = File.readlines(cookie_path).reject { |l| l.start_with?('#') || l.strip.empty? }
    cookie_str = lines.filter_map do |line|
      parts = line.chomp.split("\t")
      next if parts.length < 7

      "#{parts[5]}=#{parts[6]}"
    end.join('; ')

    raise 'No cookies obtained from Yahoo Finance' if cookie_str.empty?

    [cookie_str, crumb]
  ensure
    File.delete(cookie_path) if cookie_path && File.exist?(cookie_path)
  end

  def self.get_json(url, params)
    cookie, crumb = cookie_and_crumb
    response = Faraday.get(url) do |req|
      params.each { |k, v| req.params[k.to_s] = v }
      req.params['crumb'] = crumb
      BASE_HEADERS.merge('Cookie' => cookie).each { |k, v| req.headers[k] = v }
    end
    raise "HTTP #{response.status} from #{url}" unless response.status == 200

    JSON.parse(response.body)
  end

  def self.quote_summary(symbol, modules)
    body = get_json(
      "https://query2.finance.yahoo.com/v10/finance/quoteSummary/#{symbol}",
      modules: Array(modules).join(','), formatted: 'false'
    )
    err = body.dig('quoteSummary', 'error')
    raise err['description'] if err

    body.dig('quoteSummary', 'result', 0) or raise "No quoteSummary data for #{symbol}"
  end

  def self.chart(symbol, range: '3y', interval: '1d')
    body = get_json(
      "https://query2.finance.yahoo.com/v8/finance/chart/#{symbol}",
      interval: interval, range: range
    )
    err = body.dig('chart', 'error')
    raise err['description'] if err

    body.dig('chart', 'result', 0) or raise "No chart data for #{symbol}"
  end

  # Handles both {"raw" => n, "fmt" => "..."} and plain numeric values.
  def self.raw(hash, key)
    return nil unless hash.is_a?(Hash)

    value = hash[key]
    return nil if value.nil?

    value.is_a?(Hash) ? value['raw'] : value
  end
end

# ---------------------------------------------------------------------------
# Default portfolio — the dividend stocks researched in dividen_stocks.md
# (from https://www.marketbeat.com/dividends/best-dividend-stocks/)
# ---------------------------------------------------------------------------
DEFAULT_TICKERS = %w[F T PFE XOM ET VZ CVX AGNC NLY PSEC].freeze

# Be polite to Yahoo's unofficial API between tickers (cookie/crumb is
# cached, so this is the only per-ticker delay).
REQUEST_DELAY_SECONDS = 0.5

# Optional local cache of raw {"summary" => ..., "chart" => ...} JSON per
# ticker (lowercase filename, e.g. .yahoo_cache/aapl.json). Checked before
# any network call -- useful when Yahoo's crumb endpoint is IP-rate-limited
# (curl/Ruby's outbound network can get 429'd independently of a browser's;
# in that case fetch the data via a real browser session once and drop it
# here). Not required for normal use.
YAHOO_CACHE_DIR = File.expand_path('.yahoo_cache', __dir__)

# Scoring bounds: (low, high) domain thresholds mapped to a 0-100 score.
# These are fixed judgment calls, not portfolio-relative — a 40% payout
# ratio is "good" whether it's screened alongside two tickers or twenty.
PAYOUT_RATIO_BOUNDS    = [0.30, 1.20].freeze  # lower is better
PROFIT_MARGIN_BOUNDS   = [0.0, 0.30].freeze   # higher is better
ROE_BOUNDS             = [0.0, 0.30].freeze   # higher is better
EARNINGS_GROWTH_BOUNDS = [-0.10, 0.20].freeze # higher is better
DEBT_TO_EQUITY_BOUNDS  = [0.0, 2.0].freeze    # lower is better (D/E ratio, not %)
BETA_BOUNDS            = [0.3, 2.0].freeze    # lower is better
VOLATILITY_BOUNDS      = [0.15, 0.65].freeze  # lower is better (annualized)
DRAWDOWN_BOUNDS        = [0.10, 0.70].freeze  # lower (abs value) is better
YIELD_BOUNDS           = [0.0, 0.12].freeze   # higher is better, capped at 12%

QUALITY_WEIGHT = 0.40
RISK_WEIGHT    = 0.35
YIELD_WEIGHT   = 0.25

# ---------------------------------------------------------------------------
# Small output helpers
# ---------------------------------------------------------------------------

def heading(title)
  puts "\n#{'=' * 78}"
  puts title
  puts '=' * 78
end

# ---------------------------------------------------------------------------
# Scoring primitives — pure functions, easy to test in isolation
# ---------------------------------------------------------------------------

# Maps value to a 0-100 score where higher raw values score higher.
# low maps to 0, high maps to 100, everything outside is clamped.
def scale_higher_is_better(value, low, high)
  return nil if value.nil?

  pct = (value - low) / (high - low).to_f
  (pct.clamp(0.0, 1.0) * 100).round(1)
end

# Maps value to a 0-100 score where lower raw values score higher.
# low maps to 100, high maps to 0, everything outside is clamped.
def scale_lower_is_better(value, low, high)
  return nil if value.nil?

  pct = (high - value) / (high - low).to_f
  (pct.clamp(0.0, 1.0) * 100).round(1)
end

def annualized_volatility(returns)
  return nil if returns.nil? || returns.size < 2

  mean = returns.sum / returns.size.to_f
  variance = returns.sum { |r| (r - mean)**2 } / returns.size.to_f
  Math.sqrt(variance) * Math.sqrt(252)
end

def average(scores)
  present = scores.compact
  return nil if present.empty?

  (present.sum / present.size.to_f).round(1)
end

# Yahoo's debtToEquity is typically expressed as a percentage (e.g. 140.3
# meaning a 1.4 ratio); ratio-scale values (already < ~5) are passed through.
def normalize_debt_to_equity(value)
  return nil if value.nil?

  value > 5 ? value / 100.0 : value.to_f
end

# ---------------------------------------------------------------------------
# Fetch + derive metrics for one ticker
# ---------------------------------------------------------------------------

def extract_adjusted_prices(chart_result)
  prices = chart_result.dig('indicators', 'adjclose', 0, 'adjclose') ||
           chart_result.dig('indicators', 'quote', 0, 'close')
  Array(prices).compact
end

def load_cached_ticker_data(ticker)
  path = File.join(YAHOO_CACHE_DIR, "#{ticker.downcase}.json")
  return nil unless File.exist?(path)

  JSON.parse(File.read(path))
end

def fetch_stock_metrics(ticker)
  cached = load_cached_ticker_data(ticker)
  if cached
    summary = cached['summary']
    chart = cached['chart']
  else
    summary = YahooFinanceClient.quote_summary(
      ticker, %w[summaryDetail defaultKeyStatistics financialData price]
    )
    chart = YahooFinanceClient.chart(ticker, range: '3y')
  end

  summary_detail = summary['summaryDetail'] || {}
  key_stats      = summary['defaultKeyStatistics'] || {}
  financial_data = summary['financialData'] || {}
  price_info     = summary['price'] || {}

  prices = extract_adjusted_prices(chart)
  returns = prices.each_cons(2).map { |a, b| (b - a) / a }
  drawdown = SQA::RiskManager.max_drawdown(prices)

  {
    ticker: ticker.upcase,
    name: price_info['longName'] || price_info['shortName'],
    dividend_yield: YahooFinanceClient.raw(summary_detail, 'dividendYield'),
    payout_ratio: YahooFinanceClient.raw(summary_detail, 'payoutRatio'),
    profit_margin: YahooFinanceClient.raw(financial_data, 'profitMargins'),
    return_on_equity: YahooFinanceClient.raw(financial_data, 'returnOnEquity'),
    earnings_growth_yoy: YahooFinanceClient.raw(financial_data, 'earningsGrowth'),
    debt_to_equity: normalize_debt_to_equity(YahooFinanceClient.raw(financial_data, 'debtToEquity')),
    beta: YahooFinanceClient.raw(key_stats, 'beta') || YahooFinanceClient.raw(summary_detail, 'beta'),
    volatility: annualized_volatility(returns),
    max_drawdown: drawdown[:max_drawdown]
  }
rescue StandardError => e
  puts "  Skipping #{ticker}: #{e.message}"
  nil
end

# ---------------------------------------------------------------------------
# Score a fetched-metrics record
# ---------------------------------------------------------------------------

def score_record(record)
  quality_components = [
    scale_lower_is_better(record[:payout_ratio], *PAYOUT_RATIO_BOUNDS),
    scale_higher_is_better(record[:profit_margin], *PROFIT_MARGIN_BOUNDS),
    scale_higher_is_better(record[:return_on_equity], *ROE_BOUNDS),
    scale_higher_is_better(record[:earnings_growth_yoy], *EARNINGS_GROWTH_BOUNDS)
  ]

  risk_components = [
    scale_lower_is_better(record[:debt_to_equity], *DEBT_TO_EQUITY_BOUNDS),
    scale_lower_is_better(record[:beta], *BETA_BOUNDS),
    scale_lower_is_better(record[:volatility], *VOLATILITY_BOUNDS),
    scale_lower_is_better(record[:max_drawdown]&.abs, *DRAWDOWN_BOUNDS)
  ]

  quality_score = average(quality_components)
  risk_score = average(risk_components) # higher = safer
  yield_score = scale_higher_is_better(record[:dividend_yield], *YIELD_BOUNDS)

  composite = if quality_score && risk_score && yield_score
                ((quality_score * QUALITY_WEIGHT) +
                 (risk_score * RISK_WEIGHT) +
                 (yield_score * YIELD_WEIGHT)).round(1)
              end

  record.merge(
    quality_score: quality_score,
    risk_score: risk_score,
    yield_score: yield_score,
    composite_score: composite
  )
end

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

def fmt_pct(value)
  value.nil? ? 'N/A' : "#{(value * 100).round(1)}%"
end

def fmt_num(value)
  value.nil? ? 'N/A' : value.round(2).to_s
end

def print_metrics_table(records)
  printf("%-6s %8s %8s %8s %8s %8s %8s %8s\n",
         'Ticker', 'Yield', 'Payout', 'Margin', 'ROE', 'D/E', 'Beta', 'MaxDD')
  puts '-' * 70
  records.each do |r|
    printf("%-6s %8s %8s %8s %8s %8s %8s %8s\n",
           r[:ticker],
           fmt_pct(r[:dividend_yield]),
           fmt_pct(r[:payout_ratio]),
           fmt_pct(r[:profit_margin]),
           fmt_pct(r[:return_on_equity]),
           fmt_num(r[:debt_to_equity]),
           fmt_num(r[:beta]),
           fmt_pct(r[:max_drawdown]))
  end
end

def print_ranked_table(ranked)
  printf("%-4s %-6s %10s %10s %10s %12s\n",
         'Rank', 'Ticker', 'Quality', 'Risk', 'Yield', 'Composite')
  puts '-' * 58
  ranked.each_with_index do |r, i|
    printf("%-4d %-6s %10s %10s %10s %12s\n",
           i + 1, r[:ticker],
           fmt_num(r[:quality_score]), fmt_num(r[:risk_score]),
           fmt_num(r[:yield_score]), fmt_num(r[:composite_score]))
  end
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

SQA.init

tickers = ARGV.empty? ? DEFAULT_TICKERS : ARGV.map(&:upcase)

heading('Dividend Quality & Risk Screener (Yahoo Finance)')
puts "Tickers: #{tickers.join(', ')}"
puts "Scoring: quality #{(QUALITY_WEIGHT * 100).to_i}% + risk #{(RISK_WEIGHT * 100).to_i}% + yield #{(YIELD_WEIGHT * 100).to_i}% " \
     '(risk score is inverted — higher risk_score means lower risk)'

# Resolve the cookie/crumb once before looping over tickers, but only if at
# least one requested ticker isn't already cached -- retrying the full curl
# handshake per-ticker after a failure just hammers Yahoo harder and makes
# an IP-level rate limit worse, for no benefit -- if it fails once, it will
# fail identically for every ticker until the block clears.
needs_network = tickers.any? { |t| load_cached_ticker_data(t).nil? }

if needs_network
  begin
    YahooFinanceClient.cookie_and_crumb
  rescue StandardError => e
    puts "\nCouldn't establish a Yahoo Finance session: #{e.message}"
    puts 'Yahoo is rate-limiting this network on the crumb endpoint. Options:'
    puts '  1. Wait a while and try again.'
    puts '  2. Grab a cookie/crumb from a logged-in browser session (DevTools ' \
         "-> Network tab on finance.yahoo.com) and re-run with:\n" \
         "       YF_COOKIE='...' YF_CRUMB='...' #{$PROGRAM_NAME}"
    puts "  3. Or fetch data via a real browser session and drop it in " \
         "#{YAHOO_CACHE_DIR}/<ticker>.json as {\"summary\": ..., \"chart\": ...}."
    exit 1
  end
end

heading('Fetching data')
records = tickers.each_with_index.filter_map do |t, i|
  sleep REQUEST_DELAY_SECONDS if i.positive? && load_cached_ticker_data(t).nil?
  fetch_stock_metrics(t)
end

if records.empty?
  puts "\nNo data could be fetched for any ticker."
  exit 1
end

heading('Raw Fundamentals & Risk Metrics')
print_metrics_table(records)

scored = records.map { |r| score_record(r) }
ranked, incomplete = scored.partition { |r| r[:composite_score] }
ranked.sort_by! { |r| -r[:composite_score] }

heading('Ranked: Highest Quality, Lowest Risk, Highest Yield')
print_ranked_table(ranked)

unless incomplete.empty?
  puts "\nExcluded from ranking (missing fundamentals or price history):"
  incomplete.each { |r| puts "  #{r[:ticker]}" }
end

heading('Educational Disclaimer')
puts <<~DISCLAIMER
  This screener is for learning purposes only. Scores are derived from a
  simple, transparent weighting of a handful of metrics — they are not
  investment advice. Yahoo Finance's fundamentals API is unofficial and can
  be incomplete or wrong for some tickers. Always verify independently
  (dividend growth history, free cash flow coverage) before making any real
  financial decision.
DISCLAIMER
