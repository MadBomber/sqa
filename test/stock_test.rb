# frozen_string_literal: true

require_relative 'test_helper'

class StockTest < Minitest::Test
  def test_invalid_ticker_raises_error
    assert_raises RuntimeError do
      SQA::Stock.new(ticker: 'INVALID_TICKER_9999')
    end
  end

  def test_ticker_validation_on_initialization
    # Test with a known invalid ticker format
    assert_raises RuntimeError do
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
end
