# frozen_string_literal: true

require_relative '../test_helper'

class DataFrameFmpTest < Minitest::Test
  # A minimal stand-in for a Faraday response whose #status/#body are what
  # SQA::DataFrame::Fmp.fetch_dataframe expects. Object#stub replaces the
  # whole CONNECTION.get call (block included), so the block that sets
  # query params (and reads SQA.fmp_api_key) never actually runs here.
  class FakeResponse
    attr_reader :status, :body

    def initialize(status:, body:)
      @status = status
      @body = body
    end
  end

  VALID_JSON = [
    { "symbol" => "AAPL", "date" => "2024-01-03", "open" => 185.5, "high" => 187.0,
      "low" => 185.0, "close" => 186.2, "volume" => 48_000_000 },
    { "symbol" => "AAPL", "date" => "2024-01-02", "open" => 185.0, "high" => 186.0,
      "low" => 184.0, "close" => 185.5, "volume" => 50_000_000 }
  ].to_json

  # -- constants / interface ------------------------------------------------

  def test_connection_constant_exists
    assert_kind_of Faraday::Connection, SQA::DataFrame::Fmp::CONNECTION
  end

  def test_connection_url
    connection = SQA::DataFrame::Fmp::CONNECTION
    assert_equal 'https://financialmodelingprep.com', connection.url_prefix.to_s.chomp('/')
  end

  def test_headers_shared_with_yahoo
    assert_equal SQA::DataFrame::YahooFinance::HEADERS, SQA::DataFrame::Fmp::HEADERS
  end

  def test_header_mapping_has_required_keys
    mapping = SQA::DataFrame::Fmp::HEADER_MAPPING

    %w[date open high low close volume].each { |key| assert mapping.key?(key) }
  end

  def test_transformers_are_procs
    SQA::DataFrame::Fmp::TRANSFORMERS.each_value do |transformer|
      assert_kind_of Proc, transformer
    end
  end

  def test_responds_to_recent
    assert_respond_to SQA::DataFrame::Fmp, :recent
  end

  # -- fetch/parse/recent (isolated via stubbed CONNECTION) -----------------

  def test_recent_parses_json_into_canonical_columns
    df = with_stubbed_response(VALID_JSON) do
      SQA::DataFrame::Fmp.recent('AAPL')
    end

    assert_kind_of SQA::DataFrame, df
    assert_equal 2, df.size
    %w[timestamp open_price high_price low_price close_price volume adj_close_price].each do |col|
      assert_includes df.columns, col
    end
  end

  def test_recent_derives_adj_close_from_close
    df = with_stubbed_response(VALID_JSON) do
      SQA::DataFrame::Fmp.recent('AAPL')
    end

    assert_equal df.data["close_price"].to_a, df.data["adj_close_price"].to_a
  end

  def test_recent_returns_ascending_order
    df = with_stubbed_response(VALID_JSON) do
      SQA::DataFrame::Fmp.recent('AAPL')
    end

    timestamps = df.data["timestamp"].to_a
    assert_equal timestamps.sort, timestamps
  end

  def test_recent_from_date_excludes_boundary_row
    df = with_stubbed_response(VALID_JSON) do
      SQA::DataFrame::Fmp.recent('AAPL', from_date: Date.parse('2024-01-02'))
    end

    # from_date is exclusive (> not >=) so only the later row survives.
    assert_equal ['2024-01-03'], df.data["timestamp"].to_a
  end

  def test_recent_raises_on_error_message_payload
    assert_raises ApiError do
      with_stubbed_response({ "Error Message" => "Invalid API KEY." }.to_json) do
        SQA::DataFrame::Fmp.recent('AAPL')
      end
    end
  end

  def test_recent_raises_on_non_200_status
    assert_raises ApiError do
      with_stubbed_response('Premium Query Parameter: ...', status: 402) do
        SQA::DataFrame::Fmp.recent('BADSYMBOL')
      end
    end
  end

  def test_recent_raises_on_empty_array
    assert_raises ApiError do
      with_stubbed_response('[]') do
        SQA::DataFrame::Fmp.recent('AAPL')
      end
    end
  end

  # -- optional live integration -------------------------------------------

  def test_recent_returns_dataframe_with_valid_ticker
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    df = SQA::DataFrame::Fmp.recent('AAPL')

    assert_kind_of SQA::DataFrame, df
    assert df.size.positive?
  end

  private

  # Stub CONNECTION.get to return `body` (HTTP `status`) for the duration of
  # the block, so the fetch/parse path can be exercised without any network.
  def with_stubbed_response(body, status: 200, &)
    response = FakeResponse.new(status: status, body: body)
    SQA::DataFrame::Fmp::CONNECTION.stub(:get, response, &)
  end
end
