# lib/sqa/data_frame/stooq.rb
# frozen_string_literal: true

#
# Using the STOOQ (stooq.com) CSV download interface.
#
# STOOQ offers free daily OHLCV history with no API key and no registration
# via a simple CSV URL scheme:
#
#   https://stooq.com/q/d/l/?s=<symbol>&i=d[&d1=YYYYMMDD&d2=YYYYMMDD]
#
#   i=d  daily (also i=w weekly, i=m monthly)
#   d1   start date (inclusive)   d2  end date (inclusive)
#
# The returned CSV is already ASCENDING (oldest-first), which is exactly the
# order TA-Lib / sqa-tai require -- unlike Alpha Vantage (newest-first) we do
# not have to reverse it, but we still sort defensively.
#
# US equities on STOOQ carry a ".us" market suffix (e.g. "aapl.us"); indices
# use a "^" prefix (e.g. "^spx"). See .stooq_symbol below.
#
require 'polars'

class SQA::DataFrame
  class Stooq
    extend DailyPriceSource

    CONNECTION  = Faraday.new(url: 'https://stooq.com')
    HEADERS     = YahooFinance::HEADERS

    # STOOQ's daily CSV uses these exact column names:
    #   Date, Open, High, Low, Close, Volume
    # Remap them to SQA's canonical (Yahoo-style) column names. STOOQ's basic
    # daily feed has no adjusted close, so :adj_close_price is derived from
    # :close_price in .recent (same approach as the Alpha Vantage adapter).
    HEADER_MAPPING = {
      "Date"   => HEADERS[0],  # :timestamp
      "Open"   => HEADERS[1],  # :open_price
      "High"   => HEADERS[2],  # :high_price
      "Low"    => HEADERS[3],  # :low_price
      "Close"  => HEADERS[4],  # :close_price
      "Volume" => HEADERS[6]   # :volume
    }.freeze

    # Transformers applied AFTER column renaming. No adj_close_price here --
    # STOOQ's daily CSV doesn't provide one; .recent duplicates close_price.
    TRANSFORMERS  = {
      HEADERS[1] => ->(v) { v.to_f.round(3) },  # :open_price
      HEADERS[2] => ->(v) { v.to_f.round(3) },  # :high_price
      HEADERS[3] => ->(v) { v.to_f.round(3) },  # :low_price
      HEADERS[4] => ->(v) { v.to_f.round(3) },  # :close_price
      HEADERS[6] => lambda(&:to_i)              # :volume
    }.freeze

    # Number of calendar days of history a "compact" (full: false) fetch
    # requests. ~200 calendar days comfortably covers the ~100 trading days
    # of Alpha Vantage's compact mode, enough to warm up long indicators.
    COMPACT_DAYS = 200

    ################################################################

    # .recent(ticker, full:, from_date:) is provided by DailyPriceSource,
    # extended above; it calls .fetch_dataframe (below) for the actual HTTP
    # request and CSV parsing.

    # Fetches one page of daily price CSV from STOOQ and wraps it as an
    # SQA::DataFrame. Raises ApiError when STOOQ responds with its rate-limit
    # notice or an empty/non-CSV body (bad symbol, throttled, etc.) instead of
    # letting the CSV parser choke on it later with a confusing Polars error.
    def self.fetch_dataframe(ticker, start_date: nil)
      symbol = stooq_symbol(ticker)
      query  = "s=#{symbol}&i=d"
      query += "&d1=#{start_date.strftime('%Y%m%d')}" if start_date

      response = CONNECTION.get("/q/d/l/?#{query}").to_hash

      unless response[:status] == 200
        raise "Bad Response: #{response[:status]}"
      end

      body = response[:body].to_s

      # STOOQ signals a throttled key with a plain-text notice (HTTP 200).
      if body.include?('Exceeded the daily hits limit')
        ApiError.raise("STOOQ daily download limit exceeded for #{ticker}")
      end

      # A valid daily CSV always begins with the "Date" header. Anything else
      # (an HTML error page, "No data", an empty body) means STOOQ gave us no
      # usable rows -- most commonly an unknown symbol.
      unless body.lstrip.start_with?('Date')
        ApiError.raise("STOOQ returned no data for #{ticker}: #{body.strip[0, 120]}")
      end

      # schema_overrides values must be Ruby classes (Float/Integer) or Polars
      # dtype instances for this polars-df version (same constraint noted in
      # the Alpha Vantage adapter).
      df = Polars.read_csv(
        StringIO.new(body),
        schema_overrides: {
          "Open"   => Float,
          "High"   => Float,
          "Low"    => Float,
          "Close"  => Float,
          "Volume" => Integer
        }
      )

      # Header row present but no data rows -> valid symbol, empty range, or an
      # unknown symbol STOOQ answered with a header-only stub. Treat as no data.
      if df.height.zero?
        ApiError.raise("STOOQ returned no rows for #{ticker}")
      end

      SQA::DataFrame.new(df, transformers: TRANSFORMERS, mapping: HEADER_MAPPING)
    end
    private_class_method :fetch_dataframe

    # Translate an SQA/Yahoo-style ticker into the market-qualified symbol
    # STOOQ expects. US equities need a ".us" suffix; index symbols ("^spx")
    # and symbols already carrying an exchange suffix ("vod.uk") pass through.
    #
    # ticker String e.g. "AAPL", "^SPX", "VOD.UK"
    # Returns String the STOOQ symbol, downcased (e.g. "aapl.us")
    def self.stooq_symbol(ticker)
      t = ticker.to_s.downcase
      return t if t.start_with?('^') || t.include?('.')

      "#{t}.us"
    end
  end
end
