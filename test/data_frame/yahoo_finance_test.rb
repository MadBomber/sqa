# frozen_string_literal: true

require_relative '../test_helper'

class YahooFinanceTest < Minitest::Test
  # A minimal stand-in for a Faraday response whose #status/#body are what
  # SQA::DataFrame::YahooFinance.get_json expects.
  class FakeResponse
    attr_reader :status, :body

    def initialize(status:, body:)
      @status = status
      @body = body
    end
  end

  VALID_CHART_RESULT = {
    "timestamp" => [1_704_220_200, 1_704_306_600],
    "indicators" => {
      "quote" => [{
        "open" => [185.5, 186.0], "high" => [187.0, 188.0],
        "low" => [185.0, 185.5], "close" => [186.2, 187.5],
        "volume" => [48_000_000, 49_000_000]
      }],
      "adjclose" => [{ "adjclose" => [186.2, 187.5] }]
    }
  }.freeze

  def teardown
    # Tests set these directly to bypass the cookie/crumb handshake; reset
    # so state doesn't leak between tests or into other test files.
    SQA::DataFrame::YahooFinance.cookie = nil
    SQA::DataFrame::YahooFinance.crumb = nil
    SQA::DataFrame::YahooFinance.auth_at = nil
  end

  # -- constants / interface ------------------------------------------------

  def test_connection_constant_exists
    assert_kind_of Faraday::Connection, SQA::DataFrame::YahooFinance::CONNECTION
  end

  def test_connection_url
    connection = SQA::DataFrame::YahooFinance::CONNECTION
    assert_equal 'https://query2.finance.yahoo.com', connection.url_prefix.to_s.chomp('/')
  end

  def test_headers_has_seven_columns
    assert_equal 7, SQA::DataFrame::YahooFinance::HEADERS.size
  end

  def test_headers_contains_expected_symbols
    headers = SQA::DataFrame::YahooFinance::HEADERS

    assert_includes headers, :timestamp
    assert_includes headers, :open_price
    assert_includes headers, :high_price
    assert_includes headers, :low_price
    assert_includes headers, :close_price
    assert_includes headers, :adj_close_price
    assert_includes headers, :volume
  end

  def test_responds_to_recent
    assert_respond_to SQA::DataFrame::YahooFinance, :recent
  end

  # -- cookie_and_crumb -------------------------------------------------

  def test_cookie_and_crumb_prefers_env_override
    ENV['YF_COOKIE'] = 'test-cookie'
    ENV['YF_CRUMB'] = 'test-crumb'

    assert_equal %w[test-cookie test-crumb], SQA::DataFrame::YahooFinance.send(:cookie_and_crumb)
  ensure
    ENV.delete('YF_COOKIE')
    ENV.delete('YF_CRUMB')
  end

  # -- rows_from_chart (pure, isolated) --------------------------------------

  def test_rows_from_chart_parses_canonical_columns
    rows = SQA::DataFrame::YahooFinance.send(:rows_from_chart, VALID_CHART_RESULT)

    assert_equal 2, rows.size
    assert_equal '2024-01-02', rows.first['timestamp']
    assert_equal 185.5, rows.first['open_price']
    assert_equal 186.2, rows.first['adj_close_price']
  end

  def test_rows_from_chart_falls_back_to_close_when_no_adjclose
    result = Marshal.load(Marshal.dump(VALID_CHART_RESULT))
    result['indicators'].delete('adjclose')

    rows = SQA::DataFrame::YahooFinance.send(:rows_from_chart, result)

    assert_equal rows.first['close_price'], rows.first['adj_close_price']
  end

  def test_rows_from_chart_skips_rows_with_nil_close
    result = Marshal.load(Marshal.dump(VALID_CHART_RESULT))
    result['indicators']['quote'][0]['close'][0] = nil

    rows = SQA::DataFrame::YahooFinance.send(:rows_from_chart, result)

    assert_equal 1, rows.size
    assert_equal '2024-01-03', rows.first['timestamp']
  end

  def test_rows_from_chart_raises_on_empty_timestamps
    assert_raises ApiError do
      SQA::DataFrame::YahooFinance.send(:rows_from_chart, { 'timestamp' => [] })
    end
  end

  # -- recent (isolated via stubbed CONNECTION + forced cookie/crumb) -------

  def test_recent_returns_dataframe_in_ascending_order
    df = with_stubbed_chart(VALID_CHART_RESULT) { SQA::DataFrame::YahooFinance.recent('AAPL') }

    assert_kind_of SQA::DataFrame, df
    assert_equal 2, df.size
    timestamps = df.data["timestamp"].to_a
    assert_equal timestamps.sort, timestamps
  end

  def test_recent_raises_on_chart_error_payload
    body = { 'chart' => { 'error' => { 'description' => 'No data found' } } }.to_json

    assert_raises ApiError do
      with_stubbed_response(body) { SQA::DataFrame::YahooFinance.recent('BADSYMBOL') }
    end
  end

  def test_recent_raises_on_non_200_status
    assert_raises ApiError do
      with_stubbed_response('', status: 429) { SQA::DataFrame::YahooFinance.recent('AAPL') }
    end
  end

  # -- optional live integration -------------------------------------------

  def test_recent_returns_dataframe_with_valid_ticker
    skip "Requires network access and may be unreliable (unofficial API)" unless ENV['RUN_INTEGRATION_TESTS']

    df = SQA::DataFrame::YahooFinance.recent('AAPL')

    assert_kind_of SQA::DataFrame, df
    assert df.size.positive?
  end

  private

  # Force the cookie/crumb handshake to a fixed pair (skipping curl/network)
  # and stub CONNECTION.get to return a chart-shaped `result` wrapped in the
  # {"chart": {"result": [...]}} envelope real responses use.
  def with_stubbed_chart(result, &)
    with_stubbed_response({ 'chart' => { 'result' => [result] } }.to_json, &)
  end

  def with_stubbed_response(body, status: 200, &)
    SQA::DataFrame::YahooFinance.cookie = 'test-cookie'
    SQA::DataFrame::YahooFinance.crumb = 'test-crumb'
    SQA::DataFrame::YahooFinance.auth_at = Time.now.to_i

    response = FakeResponse.new(status: status, body: body)
    SQA::DataFrame::YahooFinance::CONNECTION.stub(:get, response, &)
  end
end
