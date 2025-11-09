# frozen_string_literal: true

require_relative '../test_helper'

class AlphaVantageTest < Minitest::Test
  def test_connection_constant_exists
    refute_nil SQA::DataFrame::AlphaVantage::CONNECTION
    assert_kind_of Faraday::Connection, SQA::DataFrame::AlphaVantage::CONNECTION
  end

  def test_headers_constant_exists
    refute_nil SQA::DataFrame::AlphaVantage::HEADERS
    assert_kind_of Array, SQA::DataFrame::AlphaVantage::HEADERS
  end

  def test_header_mapping_constant_exists
    refute_nil SQA::DataFrame::AlphaVantage::HEADER_MAPPING
    assert_kind_of Hash, SQA::DataFrame::AlphaVantage::HEADER_MAPPING
  end

  def test_transformers_constant_exists
    refute_nil SQA::DataFrame::AlphaVantage::TRANSFORMERS
    assert_kind_of Hash, SQA::DataFrame::AlphaVantage::TRANSFORMERS
  end

  def test_header_mapping_has_required_keys
    mapping = SQA::DataFrame::AlphaVantage::HEADER_MAPPING

    assert mapping.key?("date")
    assert mapping.key?("open")
    assert mapping.key?("high")
    assert mapping.key?("low")
    assert mapping.key?("close")
    assert mapping.key?("adjusted_close")
    assert mapping.key?("volume")
  end

  def test_transformers_are_procs
    SQA::DataFrame::AlphaVantage::TRANSFORMERS.values.each do |transformer|
      assert_kind_of Proc, transformer
    end
  end

  def test_responds_to_recent
    assert_respond_to SQA::DataFrame::AlphaVantage, :recent
  end

  def test_recent_requires_ticker
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    assert_raises ArgumentError do
      SQA::DataFrame::AlphaVantage.recent
    end
  end

  def test_recent_returns_dataframe_with_valid_ticker
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    df = SQA::DataFrame::AlphaVantage.recent('AAPL')

    refute_nil df
    assert_kind_of SQA::DataFrame, df
    assert df.height > 0
  end

  def test_recent_with_full_option
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    df = SQA::DataFrame::AlphaVantage.recent('AAPL', full: true)

    refute_nil df
    # Full dataset should have more rows than compact
    assert df.height > 100
  end

  def test_recent_with_from_date_option
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    from_date = Date.today - 30
    df = SQA::DataFrame::AlphaVantage.recent('AAPL', from_date: from_date)

    refute_nil df
  end

  def test_recent_handles_invalid_ticker
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    assert_raises RuntimeError do
      SQA::DataFrame::AlphaVantage.recent('INVALID_TICKER_9999')
    end
  end

  def test_connection_url
    connection = SQA::DataFrame::AlphaVantage::CONNECTION
    assert_equal 'https://www.alphavantage.co', connection.url_prefix.to_s
  end
end
