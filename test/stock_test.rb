# frozen_string_literal: true

require_relative 'test_helper'

class StockTest < Minitest::Test
  def test_invalid_ticker_raises_error
    assert_raises SQA::DataFetchError do
      SQA::Stock.new(ticker: 'INVALID_TICKER_9999')
    end
  end

  def test_ticker_validation_on_initialization
    # Test with a known invalid ticker format
    assert_raises SQA::DataFetchError do
      SQA::Stock.new(ticker: '!!!!')
    end
  end

  def test_ticker_stored_as_lowercase
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')
    assert_equal 'aapl', stock.ticker
  end

  def test_has_data_accessor
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')
    refute_nil stock.data
  end

  def test_has_df_accessor
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')
    refute_nil stock.df
  end

  def test_has_klass_accessor
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')
    refute_nil stock.klass
  end

  def test_has_transformers_accessor
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')
    refute_nil stock.transformers
  end

  def test_has_strategy_accessor
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')
    assert_respond_to stock, :strategy
    assert_respond_to stock, :strategy=
  end

  def test_delegated_ticker_method
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')
    assert_respond_to stock, :ticker
  end

  def test_delegated_name_method
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')
    assert_respond_to stock, :name
  end

  def test_delegated_exchange_method
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')
    assert_respond_to stock, :exchange
  end

  def test_delegated_source_method
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')
    assert_respond_to stock, :source
  end

  def test_delegated_indicators_method
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')
    assert_respond_to stock, :indicators
    assert_respond_to stock, :indicators=
  end

  def test_delegated_overview_method
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')
    assert_respond_to stock, :overview
  end

  def test_to_s_format
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')
    string_repr = stock.to_s

    assert_kind_of String, string_repr
    assert_match(/with \d+ data points/, string_repr)
  end

  def test_inspect_same_as_to_s
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')
    assert_equal stock.to_s, stock.inspect
  end

  def test_responds_to_save_data
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')
    assert_respond_to stock, :save_data
  end

  def test_responds_to_update
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')
    assert_respond_to stock, :update
  end

  def test_class_method_top
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    result = SQA::Stock.top

    assert_respond_to result, :top_gainers
    assert_respond_to result, :top_losers
    assert_respond_to result, :most_actively_traded
  end

  def test_default_source_is_alpha_vantage
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')
    assert_equal :alpha_vantage, stock.source
  end

  def test_connection_constant_exists
    refute_nil SQA::Stock::CONNECTION
    assert_kind_of Faraday::Connection, SQA::Stock::CONNECTION
  end

  # Test conditional CSV updates based on last timestamp
  def test_should_update_when_csv_has_old_data
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')

    # Mock the DataFrame to have yesterday's data
    yesterday = (Date.today - 1).to_s
    stock.df.data = stock.df.data.with_column(
      Polars::Series.new("timestamp", [yesterday] * stock.df.size)
    )

    # Should update because data is from yesterday
    assert stock.send(:should_update?), "Expected should_update? to be true when CSV has yesterday's data"
  end

  def test_should_not_update_when_csv_has_todays_data
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')

    # Mock the DataFrame to have today's data
    today = Date.today.to_s
    stock.df.data = stock.df.data.with_column(
      Polars::Series.new("timestamp", [today] * stock.df.size)
    )

    # Should NOT update because data is already from today
    refute stock.send(:should_update?), "Expected should_update? to be false when CSV has today's data"
  end

  def test_should_not_update_when_csv_has_future_data
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')

    # Mock the DataFrame to have tomorrow's data (edge case)
    tomorrow = (Date.today + 1).to_s
    stock.df.data = stock.df.data.with_column(
      Polars::Series.new("timestamp", [tomorrow] * stock.df.size)
    )

    # Should NOT update because data is from the future
    refute stock.send(:should_update?), "Expected should_update? to be false when CSV has future data"
  end

  def test_should_update_respects_lazy_update_config
    skip "Requires API key and network access" unless ENV['RUN_INTEGRATION_TESTS']

    stock = SQA::Stock.new(ticker: 'AAPL')

    # Save original config
    original_lazy_update = SQA.config.lazy_update

    # Enable lazy update
    SQA.config.lazy_update = true

    # Should NOT update when lazy_update is enabled
    refute stock.send(:should_update?), "Expected should_update? to be false when lazy_update is enabled"

    # Restore original config
    SQA.config.lazy_update = original_lazy_update
  end

  # Phase 2 Tests

  def test_reset_top_clears_cached_data
    # This test verifies the reset_top! method without requiring API access
    # First, ensure @top is nil (reset state)
    SQA::Stock.reset_top!

    # Verify reset_top! method exists and can be called
    assert_respond_to SQA::Stock, :reset_top!

    # After reset, @top should be nil (next call to top would fetch fresh data)
    # We can't test this directly without API access, but we verify the method exists
  end

  def test_reset_top_method_exists
    assert SQA::Stock.respond_to?(:reset_top!)
  end

  # Phase 3 Tests - Configurable Connection

  def test_connection_class_method_exists
    assert SQA::Stock.respond_to?(:connection)
  end

  def test_connection_returns_faraday_connection
    conn = SQA::Stock.connection
    assert_kind_of Faraday::Connection, conn
  end

  def test_connection_setter_exists
    assert SQA::Stock.respond_to?(:connection=)
  end

  def test_reset_connection_method_exists
    assert SQA::Stock.respond_to?(:reset_connection!)
  end

  def test_connection_can_be_injected
    # Save original connection
    original_conn = SQA::Stock.connection

    # Inject custom connection
    custom_conn = Faraday.new(url: "https://example.com")
    SQA::Stock.connection = custom_conn

    # Verify custom connection is used
    assert_equal custom_conn, SQA::Stock.connection

    # Reset to default
    SQA::Stock.reset_connection!

    # Verify default connection is restored (new instance)
    refute_equal custom_conn, SQA::Stock.connection
    assert_kind_of Faraday::Connection, SQA::Stock.connection
  end

  def test_default_connection_method_exists
    assert SQA::Stock.respond_to?(:default_connection)
  end

  def test_alpha_vantage_url_constant_exists
    assert_equal "https://www.alphavantage.co", SQA::Stock::ALPHA_VANTAGE_URL
  end
end
