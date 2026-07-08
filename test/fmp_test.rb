# frozen_string_literal: true

require_relative 'test_helper'

class FmpTest < Minitest::Test
  # Canned FMP /stable responses (trimmed to the fields SQA keeps).
  PROFILE = [{
    "symbol"      => "AAPL",
    "companyName" => "Apple Inc.",
    "marketCap"   => 3_500_000_000_000,
    "sector"      => "Technology",
    "industry"    => "Consumer Electronics",
    "ceo"         => "Mr. Timothy D. Cook",
    "beta"        => 1.24,
    "exchange"    => "NASDAQ",
    "lastDividend" => 0.99,
    "change" => 4.79 # deliberately NOT whitelisted -> must be dropped
  }].freeze

  RATIOS = [{
    "priceToEarningsRatioTTM" => 32.5,
    "netIncomePerShareTTM"    => 6.5,
    "priceToBookRatioTTM"     => 48.1,
    "priceToSalesRatioTTM"    => 8.2
  }].freeze

  EXECS = [
    { "title" => "Chief Executive Officer", "name" => "Mr. Timothy D. Cook",
      "yearBorn" => 1961, "currencyPay" => "USD" }
  ].freeze

  # Intentionally newest-first, as FMP returns it.
  DIVS = [
    { "date" => "2025-02-10", "dividend" => 0.25, "adjDividend" => 0.25 },
    { "date" => "2024-11-08", "dividend" => 0.25, "adjDividend" => 0.25 }
  ].freeze

  # Dispatch get_json by path so a single stub serves overview's 4 calls.
  RESPONDER = lambda do |path, **_params|
    case path
    when "/stable/profile"        then PROFILE
    when "/stable/ratios-ttm"     then RATIOS
    when "/stable/key-executives" then EXECS
    when "/stable/dividends"      then DIVS
    end
  end

  def with_stubbed_json(&) = SQA::FMP.stub(:get_json, RESPONDER, &)

  # -- canonical key mapping ------------------------------------------------

  def test_overview_maps_profile_fields_to_canonical_keys
    ov = with_stubbed_json { SQA::FMP.overview("AAPL") }

    assert_equal "Apple Inc.",             ov["name"]
    assert_equal 3_500_000_000_000,        ov["market_capitalization"]
    assert_equal "Technology",             ov["sector"]
    assert_equal "Consumer Electronics",   ov["industry"]
    assert_equal "Mr. Timothy D. Cook",    ov["ceo"]
  end

  def test_overview_maps_ratios_valuation_fields
    ov = with_stubbed_json { SQA::FMP.overview("AAPL") }

    assert_equal 32.5, ov["pe_ratio"]
    assert_equal 6.5,  ov["eps"]
    assert_equal 48.1, ov["price_to_book"]
    assert_equal 8.2,  ov["price_to_sales"]
  end

  def test_overview_drops_non_whitelisted_profile_fields
    ov = with_stubbed_json { SQA::FMP.overview("AAPL") }

    refute ov.key?("change"), "volatile intraday field should be dropped"
  end

  # -- executives -----------------------------------------------------------

  def test_executives_are_snake_cased
    exec = with_stubbed_json { SQA::FMP.overview("AAPL") }["executives"].first

    assert_equal "Mr. Timothy D. Cook", exec["name"]
    assert_equal 1961,                  exec["year_born"]
    assert_equal "USD",                 exec["currency_pay"]
  end

  # -- dividends ------------------------------------------------------------

  def test_dividends_returned_oldest_first
    dates = with_stubbed_json { SQA::FMP.overview("AAPL") }["dividends"].map { |d| d["date"] }

    assert_equal %w[2024-11-08 2025-02-10], dates
  end

  def test_dividends_are_snake_cased
    div = with_stubbed_json { SQA::FMP.overview("AAPL") }["dividends"].first

    assert div.key?("adj_dividend")
  end

  # -- toggles --------------------------------------------------------------

  def test_overview_can_skip_executives_and_dividends
    ov = with_stubbed_json do
      SQA::FMP.overview("AAPL", include_executives: false, include_dividends: false)
    end

    refute ov.key?("executives")
    refute ov.key?("dividends")
    assert_equal "Technology", ov["sector"] # scalars still present
  end

  # -- empty / unknown symbol ----------------------------------------------

  def test_profile_returns_empty_hash_for_unknown_symbol
    empty_responder = ->(_path, **_p) { [] }

    result = SQA::FMP.stub(:get_json, empty_responder) { SQA::FMP.profile("NOPE") }

    assert_equal({}, result)
  end

  # -- error handling (exercises real get_json via stubbed CONNECTION) ------

  def test_get_json_raises_api_error_on_error_message
    prev = SQA.instance_variable_get(:@fmp_api_key)
    SQA.fmp_api_key = "test-key"

    body = '{"Error Message":"Invalid API KEY."}'
    fake = Struct.new(:status, :body).new(401, body)
    # Callable stub: ignore the request-builder block get_json passes and
    # just return the canned error response.
    getter = ->(*_args, **_kwargs, &_blk) { fake }

    assert_raises ApiError do
      SQA::FMP::CONNECTION.stub(:get, getter) { SQA::FMP.profile("AAPL") }
    end
  ensure
    SQA.instance_variable_set(:@fmp_api_key, prev)
  end

  # -- key configuration ----------------------------------------------------

  def test_fmp_api_key_reads_env
    prev = SQA.instance_variable_get(:@fmp_api_key)
    SQA.instance_variable_set(:@fmp_api_key, nil)
    ENV["FMP_API_KEY"] = "env-key-123"

    assert_equal "env-key-123", SQA.fmp_api_key
  ensure
    ENV.delete("FMP_API_KEY")
    SQA.instance_variable_set(:@fmp_api_key, prev)
  end

  def test_fmp_api_key_raises_when_unset
    prev = SQA.instance_variable_get(:@fmp_api_key)
    SQA.instance_variable_set(:@fmp_api_key, nil)
    saved_env = ENV.delete("FMP_API_KEY")

    assert_raises SQA::ConfigurationError do
      SQA.fmp_api_key
    end
  ensure
    ENV["FMP_API_KEY"] = saved_env if saved_env
    SQA.instance_variable_set(:@fmp_api_key, prev)
  end
end
