# test/ticker_store_test.rb
# frozen_string_literal: true

require_relative 'test_helper'
require 'tmpdir'

# Behavioral coverage for SQA::Ticker against an injected store. The existing
# ticker_test.rb only asserts that methods exist.
class TickerStoreTest < Minitest::Test
  UNIVERSE = <<~CSV
    ticker,name,is_etf,exchange
    "AAPL","Apple Inc.","false","NASDAQ"
    "SPY","SPDR S&P 500 ETF","true","NYSE"
  CSV

  def setup
    @dir   = Dir.mktmpdir('sqa-ticker-store')
    @store = SQA::Store::Market.new(File.join(@dir, 'sqa.db'))

    SQA::Ticker.reset!
    SQA::Ticker.store = @store
  end

  def teardown
    SQA::Ticker.reset!
    @store.close
    FileUtils.remove_entry(@dir)
  end

  def seed
    File.write(File.join(@dir, 'universe.csv'), UNIVERSE)
    SQA::Ticker.load_from_csv(File.join(@dir, 'universe.csv'))
  end

  #############################################
  ## Lookup and validation

  def test_valid_is_true_for_a_known_symbol
    seed

    assert SQA::Ticker.valid?('AAPL')
    assert SQA::Ticker.valid?('aapl'), 'lookup should be case insensitive'
  end

  def test_valid_is_false_for_an_unknown_symbol
    seed

    refute SQA::Ticker.valid?('NOPE')
  end

  def test_lookup_returns_name_and_exchange
    seed

    assert_equal({ name: 'Apple Inc.', exchange: 'NASDAQ' }, SQA::Ticker.lookup('AAPL'))
  end

  def test_lookup_returns_nil_for_an_unknown_symbol
    seed

    assert_nil SQA::Ticker.lookup('NOPE')
  end

  def test_blank_input_never_reaches_the_store
    SQA::Ticker.store = nil # any store access would raise

    refute SQA::Ticker.valid?(nil)
    refute SQA::Ticker.valid?('')
    assert_nil SQA::Ticker.lookup(nil)
    assert_nil SQA::Ticker.lookup('')
  end

  #############################################
  ## Loading

  def test_load_from_csv_populates_the_store
    assert_equal 2, seed
    assert_equal 2, @store.ticker_count
    assert_equal 1, @store.ticker('SPY')['is_etf'], 'the is_etf flag should survive the string "true"'
  end

  def test_load_from_csv_replaces_rather_than_accumulates
    seed
    File.write(File.join(@dir, 'smaller.csv'), "ticker,name,is_etf,exchange\n\"MSFT\",\"Microsoft\",\"false\",\"NASDAQ\"\n")
    SQA::Ticker.load_from_csv(File.join(@dir, 'smaller.csv'))

    assert_equal 1, @store.ticker_count
    refute SQA::Ticker.valid?('AAPL'), 'a symbol absent from the newer snapshot is gone'
  end

  def test_data_returns_the_whole_universe_as_a_hash
    seed

    assert_equal({ name: 'Apple Inc.', exchange: 'NASDAQ' }, SQA::Ticker.data['AAPL'])
    assert_equal 2, SQA::Ticker.data.size
  end

  #############################################
  ## Download behavior

  def test_a_populated_store_is_never_re_downloaded
    seed
    called = 0

    SQA::Ticker.stub(:download, lambda {
      called += 1
      200
    }) do
      SQA::Ticker.valid?('AAPL')
      SQA::Ticker.valid?('SPY')
    end

    assert_equal 0, called, 'the universe is already present'
  end

  def test_download_is_attempted_only_once_per_process_when_it_fails
    called = 0

    SQA::Ticker.stub(:download, lambda { |*|
      called += 1
      500
    }) do
      refute SQA::Ticker.valid?('AAPL')
      refute SQA::Ticker.valid?('MSFT')
      refute SQA::Ticker.valid?('GOOG')
    end

    assert_equal SQA::Ticker::DOWNLOAD_ATTEMPTS, called,
                 'one burst of retries, not a fresh burst per lookup'
  end

  def test_a_download_raising_is_survivable
    SQA::Ticker.stub(:download, ->(*) { raise Faraday::ConnectionFailed, 'offline' }) do
      refute SQA::Ticker.valid?('AAPL'), 'validation degrades to unknown rather than raising'
    end
  end

  def test_lookups_still_work_after_a_failed_download
    SQA::Ticker.stub(:download, ->(*) { 500 }) { SQA::Ticker.valid?('AAPL') }
    seed

    assert SQA::Ticker.valid?('AAPL'), 'a later successful load should be usable'
  end
end
