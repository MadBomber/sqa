# test/stock_store_test.rb
# frozen_string_literal: true

require_relative 'test_helper'
require 'tmpdir'

# Exercises SQA::Stock against an injected market store, with no network at
# all. The pre-existing stock_test.rb skips most of its cases because they
# require live API calls; these do not.
class StockStoreTest < Minitest::Test
  # A price source that always fails, used to prove the error path wraps
  # cleanly without reaching for a network.
  class FailingSource
    TRANSFORMERS = {}.freeze

    def self.recent(*, **) = raise(ApiError, 'no network in tests')
  end

  # Stock's fallback source would otherwise be attempted after the primary
  # fails, so the fetch itself is stubbed rather than the source.
  class UnfetchableStock < SQA::Stock
    def fetch_fresh_dataframe = raise(ApiError, 'boom')
  end

  def setup
    @dir   = Dir.mktmpdir('sqa-stock-store')
    @store = SQA::Store::Market.new(File.join(@dir, 'sqa.db'))

    @original_data_dir    = SQA.config.data_dir
    @original_lazy_update = SQA.config.lazy_update

    SQA.config.data_dir    = @dir
    SQA.config.lazy_update = true # keeps should_update? from calling out

    # Creating a stock with no cached metadata triggers an optional overview
    # fetch. Stubbing the connection keeps these tests off the network (and off
    # the Alpha Vantage free tier's 25-requests-per-day budget).
    SQA::Stock.connection = Faraday.new do |builder|
      builder.adapter :test do |stub|
        stub.get(%r{/query}) { [200, {}, JSON.generate({ 'Symbol' => 'STUB', 'Name' => 'Stubbed Inc' })] }
      end
    end
  end

  def teardown
    SQA.config.data_dir    = @original_data_dir
    SQA.config.lazy_update = @original_lazy_update
    SQA::Stock.reset_connection!
    @store.close
    FileUtils.remove_entry(@dir)
  end

  def seed_prices(ticker = 'aapl', count: 3)
    @store.save_stock(ticker:, source: :fmp, name: 'Apple Inc', exchange: 'NASDAQ')
    rows = (1..count).map do |day|
      {
        'timestamp'       => format('2024-01-%02d', day),
        'open_price'      => 100.0 + day,
        'high_price'      => 101.0 + day,
        'low_price'       => 99.0 + day,
        'close_price'     => 100.5 + day,
        'adj_close_price' => 100.5 + day,
        'volume'          => 1_000 * day
      }
    end
    @store.save_prices(ticker, rows)
  end

  def write_legacy_csv(ticker, header: 'timestamp,open_price,high_price,low_price,close_price,volume,adj_close_price')
    File.write(File.join(@dir, "#{ticker}.csv"), <<~CSV)
      #{header}
      2024-01-01,100.0,101.0,99.0,100.5,1000,100.5
      2024-01-02,100.5,102.0,100.0,101.5,2000,101.5
    CSV
  end

  def stock(ticker = 'aapl', **) = SQA::Stock.new(ticker:, store: @store, **)

  #############################################
  ## Loading from the store

  def test_loads_prices_from_the_store_without_network
    seed_prices

    subject = stock

    assert_equal 3, subject.df.size
    assert_equal %w[2024-01-01 2024-01-02 2024-01-03], subject.df['timestamp'].to_a
  end

  def test_prices_arrive_oldest_first_for_talib
    seed_prices

    prices = stock.df['adj_close_price'].to_a

    assert_equal prices.sort, prices, 'TA-Lib requires ascending chronological order'
    assert_in_delta 101.5, prices.first
  end

  def test_loads_metadata_from_the_store
    seed_prices

    subject = stock

    assert_equal 'aapl',      subject.ticker
    assert_equal 'Apple Inc', subject.name
    assert_equal 'NASDAQ',    subject.exchange
    assert_equal :fmp,        subject.source
  end

  def test_dataframe_carries_the_expected_columns
    seed_prices

    assert_equal %w[timestamp open_price high_price low_price close_price adj_close_price volume].sort,
                 stock.df.columns.sort
  end

  def test_cached_predicate_requires_both_metadata_and_prices
    @store.save_stock(ticker: 'bare', source: :fmp)

    seed_prices
    assert stock('aapl').cached?

    refute SQA::Stock.allocate.tap { |s|
      s.instance_variable_set(:@store, @store)
      s.instance_variable_set(:@ticker, 'bare')
    }.cached?,
           'metadata without prices is not a usable cache'
  end

  #############################################
  ## Persisting metadata

  def test_save_data_writes_through_to_the_store
    seed_prices
    subject = stock
    subject.data.overview = { 'sector' => 'Technology' }
    subject.save_data

    assert_equal 'Technology', @store.stock('aapl')['overview']['sector']
  end

  def test_save_data_round_trips_through_a_new_instance
    seed_prices
    subject = stock
    subject.indicators = { 'rsi' => 14 }
    subject.save_data

    assert_equal({ 'rsi' => 14 }, stock.indicators)
  end

  #############################################
  ## Legacy CSV adoption

  def test_adopts_a_legacy_csv_instead_of_fetching
    write_legacy_csv('aapl')

    subject = stock

    assert_equal 2, subject.df.size
    assert_equal 2, @store.price_count('aapl'), 'the adopted rows must land in the store'
  end

  def test_adoption_leaves_the_legacy_file_untouched
    write_legacy_csv('aapl')
    before = File.read(File.join(@dir, 'aapl.csv'))

    stock

    assert_equal before, File.read(File.join(@dir, 'aapl.csv')), 'adoption reads, it does not consume'
  end

  def test_adoption_normalizes_pre_migration_column_names
    write_legacy_csv('old', header: 'date,open,high,low,close,volume')

    subject = stock('old')

    assert_includes subject.df.columns, 'open_price'
    assert_includes subject.df.columns, 'adj_close_price'
    refute_includes subject.df.columns, 'open'
    assert_in_delta 100.5, subject.df['adj_close_price'].to_a.first, 0.001,
                    'adj_close_price should fall back to close for pre-migration files'
  end

  def test_store_wins_over_a_legacy_csv
    seed_prices
    write_legacy_csv('aapl')

    assert_equal 3, stock.df.size, 'the store is authoritative once populated'
  end

  def test_adoption_happens_only_once
    write_legacy_csv('aapl')
    stock
    stock

    assert_equal 2, @store.price_count('aapl'), 'a second load must not duplicate adopted rows'
  end

  #############################################
  ## Failure

  def test_unfetchable_ticker_raises_a_helpful_error
    error = assert_raises(SQA::DataFetchError) do
      UnfetchableStock.new(ticker: 'nope', store: @store)
    end

    assert_match(/Unable to fetch data for nope/, error.message)
    assert_match(/SQA::Store::Importer/, error.message, 'the error should name the recovery path')
  end

  def test_failing_source_class_is_resolvable
    # Guards the constantize path Stock uses to turn :failing_source into a class
    assert_equal FailingSource, "#{self.class}::FailingSource".constantize
  end
end
