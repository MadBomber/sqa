# lib/sqa/data_frame/yahoo_finance.rb
# frozen_string_literal: true

#
# Yahoo Finance unofficial "chart" JSON API adapter.
#
# Yahoo dropped the server-rendered history table this adapter used to
# scrape years ago (financial.yahoo.com is now a JS-rendered SPA), so that
# approach no longer works at all. This rewrite instead calls the same
# undocumented query2.finance.yahoo.com JSON endpoints that Yahoo's own
# website uses, proven out in examples/09_dividend_quality_screener.rb.
#
# No API key and no official daily quota, which makes this a good fallback
# for SQA::Stock when the default FMP source (lib/sqa/data_frame/fmp.rb)
# fails or its ~250/day free-tier quota is exhausted. The tradeoff: it's an
# unauthenticated scrape of Yahoo's internal API, so it can break if Yahoo
# changes their site, and Yahoo does its own IP-based rate limiting on the
# crumb endpoint (429 "Too Many Requests") if hit too often from one
# network. Set YF_COOKIE / YF_CRUMB (from a real browser session, via
# DevTools -> Network tab on finance.yahoo.com) to bypass the handshake if
# that happens.
#
# Uses curl for the cookie/crumb handshake -- curl's native cookie jar
# handles redirects/SameSite reliably in a way plain Faraday/Net::HTTP does
# not.
#
require 'faraday'
require 'json'
require 'polars'
require 'tempfile'
require 'shellwords'

class SQA::DataFrame
  class YahooFinance
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

    CONNECTION = Faraday.new(url: 'https://query2.finance.yahoo.com')
    HEADERS    = [
      :timestamp,       # 0
      :open_price,      # 1
      :high_price,      # 2
      :low_price,       # 3
      :close_price,     # 4
      :adj_close_price, # 5
      :volume          # 6
    ].freeze

    # Calendar days requested for a "compact" (full: false) fetch when no
    # from_date is given. Matches Fmp and Stooq's COMPACT_DAYS.
    COMPACT_DAYS = 200

    # period1 used for a full-history fetch. Yahoo clamps this to the symbol's
    # actual listing date, so it just means "everything you have".
    EARLIEST_DATE = Date.new(1970, 1, 1)

    # Largest plausible gap between consecutive daily bars: a three-day weekend
    # plus stacked holidays.
    MAX_DAILY_GAP = 5

    class << self
      attr_accessor :cookie, :crumb, :auth_at
    end

    ################################################################

    # Get recent daily data from Yahoo Finance.
    #
    # ticker    String  the security to retrieve (e.g. "AAPL")
    # full      Boolean whether to fetch full available history (true) or
    #                   just the last COMPACT_DAYS (false)
    # from_date Date    optional; fetch data strictly AFTER this date (for
    #                   incremental updates). Overrides the compact window.
    #
    # Returns: SQA::DataFrame sorted ASCENDING (oldest to newest) for TA-Lib.
    def self.recent(ticker, full: false, from_date: nil)
      period1 = from_date || (full ? EARLIEST_DATE : Date.today - COMPACT_DAYS)
      result  = chart(ticker, period1:, period2: Date.today + 1)
      rows    = rows_from_chart(result)

      ensure_daily!(ticker, rows)

      sqa_df = SQA::DataFrame.new(rows)

      # Exclude the from_date itself (> not >=) so an incremental update that
      # overlaps the last cached day doesn't reintroduce a duplicate row.
      if from_date
        sqa_df.data = sqa_df.data.filter(Polars.col("timestamp") > from_date.to_s)
      end

      sqa_df.data = sqa_df.data.sort("timestamp", descending: false)

      sqa_df
    end

    # Fetch the chart JSON for `ticker` over an explicit period1/period2 window
    # (Dates, converted to Unix seconds).
    #
    # Yahoo's `range` parameter is deliberately not supported. Asking for
    # `range=max&interval=1d` makes Yahoo silently downsample -- it answers
    # with weekly or quarterly bars while still reporting a 1d interval, and
    # those land in a daily series looking entirely legitimate. An explicit
    # window returns true daily data, so the option that invites the mistake
    # is simply not offered.
    #
    # @return [Hash] the chart.result[0] payload
    def self.chart(ticker, period1:, period2:)
      params = {
        interval: '1d',
        period1:  period1.to_time.to_i,
        period2:  period2.to_time.to_i
      }

      body = get_json("/v8/finance/chart/#{ticker.upcase}", params)

      err = body.dig('chart', 'error')
      ApiError.raise(err['description']) if err

      result = body.dig('chart', 'result', 0)
      ApiError.raise("Yahoo Finance returned no chart data for #{ticker}") if result.nil?

      result
    end
    private_class_method :chart

    # Raises unless `rows` really are daily bars.
    #
    # Yahoo answers a 1d request with coarser data rather than an error when it
    # decides the window is too wide, so granularity has to be checked rather
    # than trusted -- weekly bars stored as daily would silently corrupt every
    # indicator computed from them. The median gap is used because a genuine
    # daily series still contains long holiday breaks.
    #
    # @param ticker [String]
    # @param rows [Array<Hash>] rows from {rows_from_chart}
    # @return [void]
    # @raise [ApiError] if the series is coarser than daily
    def self.ensure_daily!(ticker, rows)
      return if rows.size < 3

      dates = rows.map { |row| Date.parse(row['timestamp']) }.sort
      gaps  = dates.each_cons(2).map { |a, b| (b - a).to_i }.sort
      median = gaps[gaps.size / 2]
      return if median <= MAX_DAILY_GAP

      ApiError.raise(
        "Yahoo Finance returned #{median}-day bars for #{ticker}, not daily " \
        "(#{rows.size} rows over #{dates.first}..#{dates.last})"
      )
    end

    # Convert one chart() result into an array of row Hashes ready for
    # Polars::DataFrame.new, using SQA's canonical column names directly.
    def self.rows_from_chart(result)
      timestamps = Array(result['timestamp'])
      ApiError.raise("Yahoo Finance returned no rows") if timestamps.empty?

      quote    = result.dig('indicators', 'quote', 0) || {}
      adjclose = Array(result.dig('indicators', 'adjclose', 0, 'adjclose') || quote['close'])
      series   = %w[open high low close volume].map { |k| Array(quote[k]) } << adjclose

      timestamps.zip(*series).filter_map { |row| row_from_chart(row) }
    end
    # Deliberately public: Yahoo rate-limits the chart endpoint by network
    # path, so bin/sqa-yf-fetch fetches the same JSON from inside a real
    # browser and needs to convert it. Parsing lives here, in one place,
    # rather than being duplicated by that caller.

    # One row from the parallel arrays zipped in rows_from_chart:
    # [timestamp, open, high, low, close, volume, adjclose]. Returns nil for
    # a market-holiday / gap-padding row (no close price).
    def self.row_from_chart(row)
      ts, op, h, l, c, v, adj = row
      return nil if c.nil?

      {
        HEADERS[0].to_s => Time.at(ts).utc.strftime('%Y-%m-%d'),
        HEADERS[1].to_s => op&.to_f,
        HEADERS[2].to_s => h&.to_f,
        HEADERS[3].to_s => l&.to_f,
        HEADERS[4].to_s => c.to_f,
        HEADERS[5].to_s => (adj || c).to_f,
        HEADERS[6].to_s => v.to_i
      }
    end
    private_class_method :row_from_chart

    # Perform a GET against the chart API with the cookie/crumb Yahoo
    # requires, and parse the JSON body.
    def self.get_json(path, params)
      cookie, crumb = cookie_and_crumb
      query_params = params.transform_keys(&:to_s).merge('crumb' => crumb)
      headers = BASE_HEADERS.merge('Cookie' => cookie)

      response = CONNECTION.get(path, query_params, headers)

      unless response.status == 200
        ApiError.raise("Yahoo Finance HTTP #{response.status}: #{response.body.to_s[0, 120]}")
      end

      JSON.parse(response.body)
    end
    private_class_method :get_json

    # Returns a cached [cookie, crumb] pair (or the YF_COOKIE/YF_CRUMB env
    # override), re-acquiring via #acquire_cookie_and_crumb once it's older
    # than COOKIE_TTL.
    def self.cookie_and_crumb
      return [ENV['YF_COOKIE'], ENV['YF_CRUMB']] if ENV['YF_COOKIE'] && ENV['YF_CRUMB']

      stale = auth_at.nil? || (Time.now.to_i - auth_at) > COOKIE_TTL
      if stale
        self.cookie, self.crumb = acquire_cookie_and_crumb
        self.auth_at = Time.now.to_i
      end
      [cookie, crumb]
    end
    private_class_method :cookie_and_crumb

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
        ApiError.raise("Failed to obtain Yahoo Finance crumb: #{crumb}")
      end

      lines = File.readlines(cookie_path).reject { |l| l.start_with?('#') || l.strip.empty? }
      cookie_str = lines.filter_map do |line|
        parts = line.chomp.split("\t")
        next if parts.length < 7

        "#{parts[5]}=#{parts[6]}"
      end.join('; ')

      ApiError.raise('No cookies obtained from Yahoo Finance') if cookie_str.empty?

      [cookie_str, crumb]
    ensure
      File.delete(cookie_path) if cookie_path && File.exist?(cookie_path)
    end
    private_class_method :acquire_cookie_and_crumb
  end
end
