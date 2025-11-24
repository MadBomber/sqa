# frozen_string_literal: true

require_relative '../test_helper'

class YahooFinanceTest < Minitest::Test
  def test_connection_constant_exists
    refute_nil SQA::DataFrame::YahooFinance::CONNECTION
    assert_kind_of Faraday::Connection, SQA::DataFrame::YahooFinance::CONNECTION
  end

  def test_headers_constant_exists
    refute_nil SQA::DataFrame::YahooFinance::HEADERS
    assert_kind_of Array, SQA::DataFrame::YahooFinance::HEADERS
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

  def test_header_mapping_constant_exists
    refute_nil SQA::DataFrame::YahooFinance::HEADER_MAPPING
    assert_kind_of Hash, SQA::DataFrame::YahooFinance::HEADER_MAPPING
  end

  def test_header_mapping_has_required_keys
    mapping = SQA::DataFrame::YahooFinance::HEADER_MAPPING

    assert mapping.key?("Date")
    assert mapping.key?("Open")
    assert mapping.key?("High")
    assert mapping.key?("Low")
    assert mapping.key?("Close")
    assert mapping.key?("Adj Close")
    assert mapping.key?("Volume")
  end

  def test_responds_to_recent
    assert_respond_to SQA::DataFrame::YahooFinance, :recent
  end

  def test_recent_requires_ticker
    skip "Requires network access" unless ENV['RUN_INTEGRATION_TESTS']

    assert_raises ArgumentError do
      SQA::DataFrame::YahooFinance.recent
    end
  end

  def test_recent_returns_dataframe_with_valid_ticker
    skip "Requires network access and may be unreliable (scraping)" unless ENV['RUN_INTEGRATION_TESTS']

    # Yahoo Finance scraping can be unreliable
    begin
      df = SQA::DataFrame::YahooFinance.recent('AAPL')

      refute_nil df
      assert_kind_of SQA::DataFrame, df
      assert df.height > 0
    rescue => e
      skip "Yahoo Finance scraping failed: #{e.message}"
    end
  end

  def test_recent_handles_invalid_ticker
    skip "Requires network access" unless ENV['RUN_INTEGRATION_TESTS']

    assert_raises RuntimeError do
      SQA::DataFrame::YahooFinance.recent('INVALID_TICKER_9999')
    end
  end

  def test_connection_url
    connection = SQA::DataFrame::YahooFinance::CONNECTION
    assert_equal 'https://finance.yahoo.com', connection.url_prefix.to_s.chomp('/')
  end
end
