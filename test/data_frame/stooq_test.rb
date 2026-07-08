# frozen_string_literal: true

require_relative '../test_helper'

class StooqTest < Minitest::Test
  # A minimal stand-in for a Faraday response whose #to_hash returns the
  # status/body pair SQA::DataFrame::Stooq.fetch_dataframe expects.
  class FakeResponse
    def initialize(status:, body:)
      @hash = { status: status, body: body }
    end

    def to_hash = @hash
  end

  VALID_CSV = <<~CSV
    Date,Open,High,Low,Close,Volume
    2024-01-02,185.0,186.0,184.0,185.5,50000000
    2024-01-03,185.5,187.0,185.0,186.2,48000000
  CSV

  # -- constants / interface ------------------------------------------------

  def test_connection_constant_exists
    assert_kind_of Faraday::Connection, SQA::DataFrame::Stooq::CONNECTION
  end

  def test_connection_url
    connection = SQA::DataFrame::Stooq::CONNECTION
    assert_equal 'https://stooq.com', connection.url_prefix.to_s.chomp('/')
  end

  def test_headers_shared_with_yahoo
    assert_equal SQA::DataFrame::YahooFinance::HEADERS, SQA::DataFrame::Stooq::HEADERS
  end

  def test_header_mapping_has_required_keys
    mapping = SQA::DataFrame::Stooq::HEADER_MAPPING

    %w[Date Open High Low Close Volume].each { |key| assert mapping.key?(key) }
  end

  def test_transformers_are_procs
    SQA::DataFrame::Stooq::TRANSFORMERS.each_value do |transformer|
      assert_kind_of Proc, transformer
    end
  end

  def test_responds_to_recent
    assert_respond_to SQA::DataFrame::Stooq, :recent
  end

  # -- stooq_symbol (pure, isolated) ----------------------------------------

  def test_stooq_symbol_appends_us_suffix_to_bare_equity
    assert_equal 'aapl.us', SQA::DataFrame::Stooq.stooq_symbol('AAPL')
  end

  def test_stooq_symbol_passes_through_index_symbols
    assert_equal '^spx', SQA::DataFrame::Stooq.stooq_symbol('^SPX')
  end

  def test_stooq_symbol_passes_through_existing_market_suffix
    assert_equal 'vod.uk', SQA::DataFrame::Stooq.stooq_symbol('VOD.UK')
  end

  # -- fetch/parse/recent (isolated via stubbed CONNECTION) -----------------

  def test_recent_parses_csv_into_canonical_columns
    df = with_stubbed_response(VALID_CSV) do
      SQA::DataFrame::Stooq.recent('AAPL')
    end

    assert_kind_of SQA::DataFrame, df
    assert_equal 2, df.size
    %w[timestamp open_price high_price low_price close_price volume adj_close_price].each do |col|
      assert_includes df.columns, col
    end
  end

  def test_recent_derives_adj_close_from_close
    df = with_stubbed_response(VALID_CSV) do
      SQA::DataFrame::Stooq.recent('AAPL')
    end

    assert_equal df.data["close_price"].to_a, df.data["adj_close_price"].to_a
  end

  def test_recent_returns_ascending_order
    df = with_stubbed_response(VALID_CSV) do
      SQA::DataFrame::Stooq.recent('AAPL')
    end

    timestamps = df.data["timestamp"].to_a
    assert_equal timestamps.sort, timestamps
  end

  def test_recent_from_date_excludes_boundary_row
    df = with_stubbed_response(VALID_CSV) do
      SQA::DataFrame::Stooq.recent('AAPL', from_date: Date.parse('2024-01-02'))
    end

    # from_date is exclusive (> not >=) so only the later row survives.
    assert_equal ['2024-01-03'], df.data["timestamp"].to_a
  end

  def test_recent_raises_on_rate_limit_body
    assert_raises ApiError do
      with_stubbed_response('Exceeded the daily hits limit') do
        SQA::DataFrame::Stooq.recent('AAPL')
      end
    end
  end

  def test_recent_raises_on_non_csv_body
    assert_raises ApiError do
      with_stubbed_response('No data') do
        SQA::DataFrame::Stooq.recent('BADSYMBOL')
      end
    end
  end

  def test_recent_raises_on_header_only_body
    assert_raises ApiError do
      with_stubbed_response("Date,Open,High,Low,Close,Volume\n") do
        SQA::DataFrame::Stooq.recent('AAPL')
      end
    end
  end

  # -- optional live integration -------------------------------------------

  def test_recent_returns_dataframe_with_valid_ticker
    skip "Requires network access" unless ENV['RUN_INTEGRATION_TESTS']

    df = SQA::DataFrame::Stooq.recent('AAPL')

    assert_kind_of SQA::DataFrame, df
    assert df.size.positive?
  end

  private

  # Stub CONNECTION.get to return `body` (HTTP 200) for the duration of the
  # block, so the fetch/parse path can be exercised without any network.
  def with_stubbed_response(body, &)
    response = FakeResponse.new(status: 200, body: body)
    SQA::DataFrame::Stooq::CONNECTION.stub(:get, response, &)
  end
end
