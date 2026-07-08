# lib/sqa/fmp.rb
# frozen_string_literal: true

#
# Financial Modeling Prep (FMP) company-fundamentals client.
# https://site.financialmodelingprep.com/developer/docs/stable
#
# Fills the gaps Alpha Vantage's OVERVIEW leaves for SQA::Stock: company
# executives and dividend payment history, alongside the usual name / sector /
# industry / P/E / market cap. The result of .overview is a flat, snake_cased
# Hash (plus :executives and :dividends arrays) shaped to merge straight into
# SQA::DataFrame::Data#overview -- the same slot Alpha Vantage already fills.
#
# Uses FMP's "stable" REST API. A free API key (FMP_API_KEY env var) allows
# ~250 US-only calls/day; .overview spends up to 4 (profile, ratios-ttm,
# key-executives, dividends) per ticker -- toggle the last two off to save
# calls. Keys are read from the environment only (never hardcoded), matching
# the Alpha Vantage convention.
#
require 'faraday'
require 'json'

module SQA
  class FMP
    BASE_URL   = 'https://financialmodelingprep.com'
    CONNECTION = Faraday.new(url: BASE_URL)

    # FMP profile/quote field  =>  canonical SQA overview key.
    # Keys are chosen to line up with the snake_case names Alpha Vantage's
    # OVERVIEW already writes into overview (e.g. "pe_ratio", "sector",
    # "market_capitalization"), so downstream code reads the same keys
    # regardless of which source populated them. Anything not listed here is
    # passed through with its FMP name underscored.
    CANONICAL_KEYS = {
      "companyName"             => "name",
      "marketCap"               => "market_capitalization",
      "lastDividend"            => "dividend_per_share",
      "fullTimeEmployees"       => "full_time_employees",
      "ipoDate"                 => "ipo_date",
      "priceToEarningsRatioTTM" => "pe_ratio",        # from /ratios-ttm
      "netIncomePerShareTTM"    => "eps",             # from /ratios-ttm (TTM EPS)
      "priceToBookRatioTTM"     => "price_to_book",   # from /ratios-ttm
      "priceToSalesRatioTTM"    => "price_to_sales"   # from /ratios-ttm
    }.freeze

    # Scalar profile fields worth keeping (a whitelist keeps the overview Hash
    # tidy and predictable rather than dumping every FMP field, some of which
    # are volatile intraday values like "change"/"volume").
    PROFILE_FIELDS = %w[
      companyName symbol exchange sector industry ceo beta description website
      country fullTimeEmployees ipoDate isin cik marketCap lastDividend range
    ].freeze

    # Valuation scalars mined from /ratios-ttm. FMP's stable /quote endpoint no
    # longer carries P/E or EPS (verified live 2026-07-02), so P/E comes from
    # priceToEarningsRatioTTM and TTM EPS from netIncomePerShareTTM here.
    RATIOS_FIELDS = %w[
      priceToEarningsRatioTTM netIncomePerShareTTM priceToBookRatioTTM priceToSalesRatioTTM
    ].freeze

    ################################################################

    # Build a company fundamentals Hash for `ticker`, ready to merge into
    # SQA::Stock#overview.
    #
    # ticker             String  the security (e.g. "AAPL")
    # include_executives Boolean fetch the key-executives list (1 extra call)
    # include_dividends  Boolean fetch the dividend history  (1 extra call)
    #
    # Returns: Hash with snake_case scalar keys (name, sector, industry,
    #          pe_ratio, market_capitalization, ceo, ...) plus "executives"
    #          and "dividends" arrays when requested.
    def self.overview(ticker, include_executives: true, include_dividends: true)
      result = {}

      result.merge!(normalize(profile(ticker), PROFILE_FIELDS))
      result.merge!(normalize(ratios(ticker),  RATIOS_FIELDS))

      result["executives"] = executives(ticker) if include_executives
      result["dividends"]  = dividends(ticker)   if include_dividends

      result
    end

    # GET /stable/profile -- company profile (name, sector, industry, ceo,
    # beta, description, exchange, ...). Returns the first (only) record Hash,
    # or {} if FMP returns no rows (unknown symbol).
    def self.profile(ticker)
      first_record(get_json("/stable/profile", symbol: ticker))
    end

    # GET /stable/ratios-ttm -- trailing-twelve-month valuation ratios, mined
    # here for P/E (priceToEarningsRatioTTM), TTM EPS (netIncomePerShareTTM),
    # price/book and price/sales. Returns the first record Hash or {}.
    def self.ratios(ticker)
      first_record(get_json("/stable/ratios-ttm", symbol: ticker))
    end

    # GET /stable/key-executives -- array of {title, name, pay, currencyPay,
    # gender, yearBorn, ...}, snake_cased. This is the field Alpha Vantage and
    # free Finnhub don't provide.
    def self.executives(ticker)
      records = get_json("/stable/key-executives", symbol: ticker)
      Array(records).map { |exec| underscore_keys(exec) }
    end

    # GET /stable/dividends -- dividend payment history, newest-first from FMP;
    # returned oldest-first here to match SQA's ascending (TA-Lib) convention.
    # Each entry: {date, record_date, payment_date, declaration_date,
    # dividend, adj_dividend, yield, frequency}.
    def self.dividends(ticker)
      records = get_json("/stable/dividends", symbol: ticker)
      Array(records).map { |div| underscore_keys(div) }.sort_by { |d| d["date"].to_s }
    end

    ################################################################

    # Perform a GET against the FMP stable API and parse the JSON body.
    # Raises ApiError on FMP's error payload ({"Error Message": ...}, returned
    # with a 401/403 for a bad/absent key) or any non-200 without valid JSON.
    #
    # path   String  e.g. "/stable/profile"
    # params Hash     query params (apikey is added automatically)
    def self.get_json(path, **params)
      response = CONNECTION.get(path) do |req|
        params.each { |key, value| req.params[key.to_s] = value }
        req.params['apikey'] = SQA.fmp_api_key
      end

      body = begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        nil
      end

      # FMP reports invalid keys / plan limits as {"Error Message": "..."}.
      if body.is_a?(Hash) && body["Error Message"]
        ApiError.raise("FMP: #{body['Error Message']}")
      end

      unless response.status == 200
        ApiError.raise("FMP HTTP #{response.status}: #{response.body.to_s[0, 120]}")
      end

      body
    end
    private_class_method :get_json

    # FMP list endpoints return a JSON array; single-entity ones a 1-element
    # array. Reduce to the first Hash, or {} when there are no rows.
    def self.first_record(body)
      record = body.is_a?(Array) ? body.first : body
      record.is_a?(Hash) ? record : {}
    end
    private_class_method :first_record

    # Reduce an FMP record to the whitelisted `fields`, renaming via
    # CANONICAL_KEYS where a canonical SQA name exists and underscoring the
    # rest. Missing fields are simply skipped.
    def self.normalize(record, fields)
      fields.each_with_object({}) do |field, acc|
        next unless record.key?(field)

        key = CANONICAL_KEYS[field] || field.underscore
        acc[key] = record[field]
      end
    end
    private_class_method :normalize

    # Snake_case every key in a flat FMP record Hash (used for the executives
    # and dividends arrays, which we keep wholesale rather than whitelisting).
    def self.underscore_keys(record)
      return {} unless record.is_a?(Hash)

      record.transform_keys { |k| k.to_s.underscore }
    end
    private_class_method :underscore_keys
  end
end
