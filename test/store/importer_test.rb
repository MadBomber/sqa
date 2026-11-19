# test/store/importer_test.rb
# frozen_string_literal: true

require_relative '../test_helper'
require 'tmpdir'

class StoreImporterTest < Minitest::Test
  def setup
    @dir       = Dir.mktmpdir('sqa-importer')
    @data_dir  = File.join(@dir, 'data')
    FileUtils.mkdir_p(@data_dir)

    @market    = SQA::Store::Market.new(File.join(@dir, 'sqa.db'))
    @portfolio = SQA::Store::Portfolio.new(File.join(@dir, 'portfolio.db'))
  end

  def teardown
    @market.close
    @portfolio.close
    FileUtils.remove_entry(@dir)
  end

  def importer = SQA::Store::Importer.new(data_dir: @data_dir, market: @market, portfolio: @portfolio)

  def write(name, content) = File.write(File.join(@data_dir, name), content)

  def write_prices(ticker, header: 'timestamp,open_price,high_price,low_price,close_price,volume,adj_close_price')
    write("#{ticker}.csv", <<~CSV)
      #{header}
      1999-11-01,80.0,80.69,77.37,77.62,2487300,77.62
      1999-11-02,77.62,81.0,77.0,80.25,3100400,80.25
    CSV
  end

  def write_metadata(ticker, source: 'fmp')
    write("#{ticker}.json", JSON.generate(
                              { 'ticker' => ticker, 'name' => nil, 'exchange' => nil,
                                'source' => source, 'indicators' => {}, 'overview' => { 'sector' => 'Tech' } }
                            ))
  end

  def write_yahoo_cache(ticker)
    write("#{ticker}.json", JSON.generate({ 'summary' => { 'price' => {} }, 'chart' => { 'timestamp' => [1, 2] } }))
  end

  #############################################
  ## Classification

  def test_classify_distinguishes_the_two_json_schemas
    assert_equal :metadata,    SQA::Store::Importer.classify({ 'ticker' => 'aapl' })
    assert_equal :yahoo_cache, SQA::Store::Importer.classify({ 'summary' => {}, 'chart' => {} })
    assert_equal :yahoo_cache, SQA::Store::Importer.classify({ 'chart' => {} })
    assert_equal :unknown,     SQA::Store::Importer.classify({ 'something' => 1 })
    assert_equal :unknown,     SQA::Store::Importer.classify([1, 2, 3])
    assert_equal :unknown,     SQA::Store::Importer.classify(nil)
  end

  #############################################
  ## Prices and metadata

  def test_imports_prices_oldest_first
    write_prices('aapl')
    write_metadata('aapl')

    report = importer.run

    assert_equal({ 'aapl' => 2 }, report.prices)
    assert_equal(%w[1999-11-01 1999-11-02], @market.prices('aapl').map { |r| r['timestamp'] })
  end

  def test_imports_metadata_including_overview
    write_metadata('aapl')

    importer.run

    assert_equal 'Tech', @market.stock('aapl')['overview']['sector']
    assert_equal 'fmp',  @market.stock('aapl')['source']
  end

  def test_price_csv_without_metadata_still_imports
    write_prices('orphan')

    report = importer.run

    assert_equal({ 'orphan' => 2 }, report.prices)
    assert @market.stock?('orphan'), 'a parent stocks row must be created for the foreign key'
  end

  def test_imports_legacy_column_names
    write_prices('old', header: 'date,open,high,low,close,volume')

    importer.run
    row = @market.prices('old').first

    assert_equal '1999-11-01', row['timestamp']
    assert_in_delta 80.0,  row['open_price']
    assert_in_delta 77.62, row['close_price']
    assert_in_delta 77.62, row['adj_close_price'], 0.001,
                    'adj_close_price should fall back to close for pre-migration files'
  end

  def test_import_is_idempotent
    write_prices('aapl')
    importer.run
    importer.run

    assert_equal 2, @market.price_count('aapl'), 'a second run must not duplicate rows'
  end

  def test_blank_and_headerless_rows_are_ignored
    write('sparse.csv', "timestamp,close_price\n2024-01-01,10.0\n,\n\n2024-01-02,11.0\n")

    importer.run

    assert_equal 2, @market.price_count('sparse')
  end

  def test_empty_csv_is_skipped_not_fatal
    write('empty.csv', "timestamp,close_price\n")

    report = importer.run

    assert_includes report.skipped, 'empty.csv'
    assert_empty report.prices
  end

  #############################################
  ## Quarantine

  def test_yahoo_cache_files_are_quarantined_not_imported
    write_yahoo_cache('aapl')
    write_prices('aapl')

    report = importer.run

    assert_equal ['aapl.json'], report.quarantined
    assert_empty report.metadata
    refute File.exist?(File.join(@data_dir, 'aapl.json')), 'the impostor must be moved out of the way'
    assert File.exist?(File.join(@data_dir, 'quarantined_yahoo_cache', 'aapl.json')), 'and it must still exist'
  end

  def test_quarantined_file_content_is_preserved
    write_yahoo_cache('aapl')

    importer.run
    moved = JSON.parse(File.read(File.join(@data_dir, 'quarantined_yahoo_cache', 'aapl.json')))

    assert_equal [1, 2], moved['chart']['timestamp'], 'quarantine moves, it never rewrites'
  end

  def test_metadata_and_cache_files_are_sorted_by_schema_not_name
    write_metadata('msft')
    write_yahoo_cache('aapl')

    report = importer.run

    assert_equal ['msft'],      report.metadata
    assert_equal ['aapl.json'], report.quarantined
  end

  def test_unparseable_json_is_skipped
    write('broken.json', '{not json')

    report = importer.run

    assert_includes report.skipped, 'broken.json'
  end

  def test_json_with_neither_schema_is_skipped_and_left_alone
    write('mystery.json', JSON.generate({ 'something' => 1 }))

    report = importer.run

    assert_includes report.skipped, 'mystery.json'
    assert File.exist?(File.join(@data_dir, 'mystery.json')), 'an unrecognized file is not ours to move'
  end

  #############################################
  ## Ticker universe

  def test_imports_the_newest_ticker_universe_snapshot
    write('dumbstockapi-2025-01-01T00:00:00.000Z.csv', "ticker,name,is_etf,exchange\nOLD,Old Corp,\"null\",NYSE\n")
    write('dumbstockapi-2025-06-01T00:00:00.000Z.csv',
          "ticker,name,is_etf,exchange\nAAPL,Apple Inc,\"false\",NASDAQ\nSPY,S&P 500 ETF,\"true\",NYSE\n")

    report = importer.run

    assert_equal 2, report.tickers
    assert @market.valid_ticker?('AAPL')
    refute @market.valid_ticker?('OLD'), 'only the newest snapshot should survive'
    assert_equal 1, @market.ticker('SPY')['is_etf']
    assert_equal 0, @market.ticker('AAPL')['is_etf']
  end

  def test_ticker_universe_csv_is_not_mistaken_for_prices
    write('dumbstockapi-2025-06-01T00:00:00.000Z.csv', "ticker,name,is_etf,exchange\nAAPL,Apple,\"false\",NASDAQ\n")

    report = importer.run

    assert_empty report.prices
  end

  #############################################
  ## Legacy portfolio CSVs

  def test_imports_legacy_positions_as_open_rows
    write('portfolio.csv', "ticker,shares,avg_cost,total_cost\nAAPL,10,150.0,1500.0\n")

    report = importer.run
    id = @portfolio.portfolio('Imported Portfolio')['id']

    assert_equal ['Imported Portfolio'], report.portfolios
    assert_equal(%w[open], @portfolio.trades(id).map { |t| t['action'] })
    assert_in_delta 10.0,  @portfolio.position(id, 'aapl')['shares']
    assert_in_delta 150.0, @portfolio.position(id, 'aapl')['avg_cost']
  end

  def test_imports_legacy_trades
    write('trades.csv', "date,ticker,action,shares,price,total,commission\n2024-01-01,AAPL,buy,10,150.0,1500.0,1.0\n")

    importer.run
    id = @portfolio.portfolio('Imported Portfolio')['id']

    assert_equal(%w[buy], @portfolio.trades(id).map { |t| t['action'] })
    assert_equal '2024-01-01', @portfolio.trades(id).first['traded_on']
  end

  def test_inconsistent_legacy_trades_are_skipped_not_fatal
    write('trades.csv', <<~CSV)
      date,ticker,action,shares,price,total,commission
      2024-01-01,AAPL,sell,10,150.0,1500.0,0.0
      2024-01-02,MSFT,buy,5,200.0,1000.0,0.0
    CSV

    report = importer.run
    id = @portfolio.portfolio('Imported Portfolio')['id']

    assert_equal 1, report.skipped.size, 'the uncovered sale should be reported'
    assert_equal %w[msft], @portfolio.positions(id).map { |p| p['ticker'] }, 'the valid trade still imports'
  end

  def test_no_portfolio_created_when_no_legacy_csvs_exist
    write_prices('aapl')

    assert_empty importer.run.portfolios
  end

  #############################################
  ## Dry run

  def test_dry_run_reports_without_writing
    write_prices('aapl')
    write_metadata('aapl')
    write_yahoo_cache('msft')

    report = importer.run(dry_run: true)

    assert_equal({ 'aapl' => 2 }, report.prices)
    assert_equal ['msft.json'],   report.quarantined
    assert_equal 0, @market.price_count('aapl'), 'dry run must not write prices'
    refute @market.stock?('aapl'), 'dry run must not write metadata'
    assert File.exist?(File.join(@data_dir, 'msft.json')), 'dry run must not move files'
  end

  #############################################
  ## Report

  def test_report_totals_price_rows
    write_prices('aapl')
    write_prices('msft')

    report = importer.run

    assert_equal 4, report.price_rows
    assert_match(/2 ticker\(s\), 4 row\(s\)/, report.to_s)
  end
end
