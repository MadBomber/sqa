# test/store/market_test.rb
# frozen_string_literal: true

require_relative '../test_helper'
require 'tmpdir'

class StoreMarketTest < Minitest::Test
  def setup
    @dir   = Dir.mktmpdir('sqa-market-store')
    @store = SQA::Store::Market.new(File.join(@dir, 'sqa.db'))
  end

  def teardown
    @store.close
    FileUtils.remove_entry(@dir)
  end

  # Deliberately out of order, so a test that asserts ascending output is
  # actually testing the store rather than the fixture.
  def sample_rows
    [
      price_row('2024-01-03', 3.0, 300),
      price_row('2024-01-01', 1.0, 100),
      price_row('2024-01-02', 2.0, 200)
    ]
  end

  def price_row(date, base, volume)
    {
      'timestamp'       => date,
      'open_price'      => base,
      'high_price'      => base + 1.0,
      'low_price'       => base - 0.5,
      'close_price'     => base + 0.5,
      'adj_close_price' => base + 0.5,
      'volume'          => volume
    }
  end

  def test_migrations_establish_schema_version
    assert_equal 1, @store.schema_version
  end

  def test_reopening_does_not_remigrate
    path = @store.path
    @store.close

    reopened = SQA::Store::Market.new(path)
    assert_equal 1, reopened.schema_version
    reopened.close
  end

  def test_save_stock_round_trips_json_columns
    @store.save_stock(ticker: 'AAPL', source: :fmp, name: 'Apple Inc', exchange: 'NASDAQ',
                      overview: { 'sector' => 'Technology' }, indicators: { 'rsi' => 14 })

    record = @store.stock('aapl')

    assert_equal 'aapl',       record['ticker']
    assert_equal 'Apple Inc',  record['name']
    assert_equal 'fmp',        record['source']
    assert_equal 'Technology', record['overview']['sector']
    assert_equal 14,           record['indicators']['rsi']
  end

  def test_ticker_lookup_is_case_insensitive
    @store.save_stock(ticker: 'AAPL', source: :fmp)

    assert @store.stock?('aapl')
    assert @store.stock?('AAPL')
    assert @store.stock?('  Aapl  ')
  end

  def test_stock_returns_nil_when_absent
    assert_nil @store.stock('nope')
  end

  def test_save_stock_updates_without_clobbering_known_name
    @store.save_stock(ticker: 'aapl', source: :fmp, name: 'Apple Inc')
    @store.save_stock(ticker: 'aapl', source: :yahoo_finance)

    record = @store.stock('aapl')

    assert_equal 'Apple Inc',     record['name'], 'a later write without a name must not erase the known one'
    assert_equal 'yahoo_finance', record['source']
  end

  def test_prices_are_returned_oldest_first
    @store.save_stock(ticker: 'aapl', source: :fmp)
    @store.save_prices('aapl', sample_rows)

    dates = @store.prices('aapl').map { |row| row['timestamp'] }

    assert_equal %w[2024-01-01 2024-01-02 2024-01-03], dates,
                 'TA-Lib requires ascending chronological order'
  end

  def test_saving_overlapping_prices_updates_rather_than_duplicates
    @store.save_stock(ticker: 'aapl', source: :fmp)
    @store.save_prices('aapl', sample_rows)
    @store.save_prices('aapl', [{ 'timestamp' => '2024-01-02', 'close_price' => 99.0, 'adj_close_price' => 99.0 }])

    assert_equal 3, @store.price_count('aapl'), 'the composite primary key must absorb the repeat'
    assert_equal 99.0, @store.prices('aapl')[1]['close_price']
  end

  def test_prices_accept_symbol_keys_and_legacy_column_names
    @store.save_stock(ticker: 'aapl', source: :fmp)
    @store.save_prices('aapl', [{ timestamp: '2024-02-01', open: 5.0, high: 6.0, low: 4.0, close: 5.5, volume: 10 }])

    row = @store.prices('aapl').first

    assert_equal 5.0, row['open_price']
    assert_equal 5.5, row['close_price']
    assert_equal 5.5, row['adj_close_price'], 'adj_close_price should fall back to close when absent'
  end

  def test_prices_can_be_bounded_by_date
    @store.save_stock(ticker: 'aapl', source: :fmp)
    @store.save_prices('aapl', sample_rows)

    assert_equal(%w[2024-01-02 2024-01-03], @store.prices('aapl', from: '2024-01-02').map { |r| r['timestamp'] })
    assert_equal(%w[2024-01-01],            @store.prices('aapl', to: Date.new(2024, 1, 1)).map { |r| r['timestamp'] })
  end

  def test_coverage_reports_range_without_reading_rows
    @store.save_stock(ticker: 'aapl', source: :fmp)
    @store.save_prices('aapl', sample_rows)

    assert_equal({ first: '2024-01-01', last: '2024-01-03', count: 3 }, @store.coverage('aapl'))
    assert_equal '2024-01-03', @store.last_price_date('aapl')
  end

  def test_coverage_of_unknown_ticker_is_empty
    assert_equal({ first: nil, last: nil, count: 0 }, @store.coverage('nope'))
  end

  def test_deleting_a_stock_cascades_to_its_prices
    @store.save_stock(ticker: 'aapl', source: :fmp)
    @store.save_prices('aapl', sample_rows)

    assert_equal 1, @store.delete_stock('aapl')
    assert_equal 0, @store.price_count('aapl')
  end

  def test_saving_empty_price_rows_is_a_noop
    @store.save_stock(ticker: 'aapl', source: :fmp)

    assert_equal 0, @store.save_prices('aapl', [])
    assert_equal 0, @store.save_prices('aapl', nil)
  end

  def test_replace_tickers_is_a_snapshot_not_an_accumulation
    @store.replace_tickers([{ symbol: 'AAPL', name: 'Apple', exchange: 'NASDAQ', country: 'US' },
                            { symbol: 'ENRN', name: 'Enron', exchange: 'NYSE', country: 'US' }])
    @store.replace_tickers([{ symbol: 'AAPL', name: 'Apple Inc', exchange: 'NASDAQ', country: 'US' }])

    assert_equal 1, @store.ticker_count, 'a symbol gone from upstream must disappear here too'
    assert @store.valid_ticker?('AAPL')
    refute @store.valid_ticker?('ENRN')
    assert_equal 'Apple Inc', @store.ticker('aapl')['name']
  end
end
