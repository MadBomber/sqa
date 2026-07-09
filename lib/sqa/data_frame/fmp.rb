# lib/sqa/data_frame/fmp.rb
# frozen_string_literal: true

#
# Financial Modeling Prep (FMP) price-history adapter.
#
# Alpha Vantage's free tier allows only 25 requests/day (and its
# outputsize=full history is now premium-only, capping free-tier history at
# ~100 trading days). FMP's free tier allows ~250 requests/day and returns
# up to ~5 years of daily OHLCV with no bot-protection wall -- unlike Stooq,
# which now requires solving a JavaScript proof-of-work challenge on every
# request and so cannot be reached by a plain HTTP client at all. This makes
# FMP SQA::Stock's default price source (see SQA.fmp_api_key /
# FMP_API_KEY). SQA::FMP (lib/sqa/fmp.rb) is the separate company-
# fundamentals client that fills the same "overview" slot Alpha Vantage's
# OVERVIEW endpoint used to.
#
# FMP's free "historical-price-eod/full" endpoint does not include a
# split/dividend-adjusted close, so -- same as the Stooq adapter --
# :adj_close_price is derived by duplicating :close_price.
#
# Named Fmp (not FMP) because SQA::Stock resolves `source: :fmp` to a class
# name via String#camelize, which capitalizes only the leading letter of an
# underscore-free word ("fmp" -> "Fmp") -- unlike SQA::FMP (lib/sqa/fmp.rb),
# which isn't resolved that way and keeps the conventional acronym casing.
#
require 'faraday'
require 'json'
require 'polars'

class SQA::DataFrame
  class Fmp
    extend DailyPriceSource

    CONNECTION  = Faraday.new(url: 'https://financialmodelingprep.com')
    HEADERS     = YahooFinance::HEADERS

    # FMP's historical-price-eod JSON uses these exact field names.
    HEADER_MAPPING = {
      "date"   => HEADERS[0],  # :timestamp
      "open"   => HEADERS[1],  # :open_price
      "high"   => HEADERS[2],  # :high_price
      "low"    => HEADERS[3],  # :low_price
      "close"  => HEADERS[4],  # :close_price
      "volume" => HEADERS[6]   # :volume
    }.freeze

    # Transformers applied AFTER column renaming. No adj_close_price here --
    # FMP's free endpoint doesn't provide one; .recent duplicates close_price.
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
    # request and JSON parsing.

    # Fetches daily price JSON from FMP and wraps it as an SQA::DataFrame.
    # Raises ApiError on FMP's error payload ({"Error Message": ...}, plan
    # limits, invalid symbol) or any non-200 response.
    def self.fetch_dataframe(ticker, start_date: nil)
      params = { 'symbol' => ticker.upcase, 'apikey' => SQA.fmp_api_key }
      params['from'] = start_date.strftime('%Y-%m-%d') if start_date

      response = CONNECTION.get("/stable/historical-price-eod/full", params)

      body = begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        nil
      end

      # FMP reports invalid keys / plan limits / premium-only symbols as
      # {"Error Message": "..."} -- sometimes with a 200, sometimes not, so
      # check this before the status check below.
      if body.is_a?(Hash) && body["Error Message"]
        ApiError.raise("FMP: #{body['Error Message']}")
      end

      unless response.status == 200
        ApiError.raise("FMP HTTP #{response.status}: #{response.body.to_s[0, 120]}")
      end

      records = Array(body)
      if records.empty?
        ApiError.raise("FMP returned no rows for #{ticker}")
      end

      df = Polars::DataFrame.new(records.map { |r| r.slice("date", "open", "high", "low", "close", "volume") })
      SQA::DataFrame.new(df, transformers: TRANSFORMERS, mapping: HEADER_MAPPING)
    end
    private_class_method :fetch_dataframe
  end
end
