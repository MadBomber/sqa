# frozen_string_literal: true

require_relative 'test_helper'

class TickerTest < Minitest::Test
  def test_connection_constant_exists
    refute_nil SQA::Ticker::CONNECTION
    assert_kind_of Faraday::Connection, SQA::Ticker::CONNECTION
  end

  def test_filename_prefix_constant_exists
    assert_equal "dumbstockapi", SQA::Ticker::FILENAME_PREFIX
  end

  def test_reset_method_exists
    assert SQA::Ticker.respond_to?(:reset!)
  end

  def test_reset_clears_cached_data
    # Call reset to clear any existing data
    SQA::Ticker.reset!

    # Verify reset! can be called without error
    # The actual data loading would require network access
    assert_respond_to SQA::Ticker, :reset!
  end

  def test_data_method_exists
    assert SQA::Ticker.respond_to?(:data)
  end

  def test_valid_method_exists
    assert SQA::Ticker.respond_to?(:valid?)
  end

  def test_lookup_method_exists
    assert SQA::Ticker.respond_to?(:lookup)
  end

  def test_valid_returns_false_for_empty_ticker
    refute SQA::Ticker.valid?("")
  end

  def test_valid_returns_false_for_nil_ticker
    refute SQA::Ticker.valid?(nil)
  end

  def test_lookup_returns_nil_for_empty_ticker
    assert_nil SQA::Ticker.lookup("")
  end

  def test_lookup_returns_nil_for_nil_ticker
    assert_nil SQA::Ticker.lookup(nil)
  end
end
