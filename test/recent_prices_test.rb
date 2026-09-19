# test/recent_prices_test.rb
# frozen_string_literal: true

require_relative 'test_helper'
require 'tmpdir'

# bin/sqa-recent-prices has no .rb extension (matching bin/sqa-summary), so
# require_relative cannot find it by name. Loading it defines
# SQA::RecentPrices and SQA::RecentPricesReport without running the CLI,
# which is guarded by $PROGRAM_NAME == __FILE__.
load File.expand_path('../bin/sqa-recent-prices', __dir__)

class RecentPricesTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir('sqa-recent-prices')
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def recent_prices(limit: 30, ticker: nil) = SQA::RecentPrices.new(data_dir: @dir, limit:, ticker:)

  def seed_market
    store = SQA::Store::Market.new(File.join(@dir, 'sqa.db'))
    store.save_stock(ticker: 'aapl', source: :fmp, name: 'Apple Inc')
    store.save_prices('aapl', (1..5).map { |d| price_row("2024-01-0#{d}", d) })
    store.save_stock(ticker: 'bare', source: :fmp)
    store.close
  end

  def price_row(date, day)
    { 'timestamp' => date, 'open_price' => 100.0 + day, 'high_price' => 101.0 + day, 'low_price' => 99.0 + day,
      'close_price' => 100.0 + day, 'adj_close_price' => 100.0 + day, 'volume' => 1_000 * day }
  end

  #############################################
  ## RecentPrices — read-only guarantee

  def test_collecting_does_not_create_a_database
    result = recent_prices.to_a

    assert_empty result
    refute File.exist?(File.join(@dir, 'sqa.db')), 'collecting must not bring sqa.db into existence'
  end

  #############################################
  ## RecentPrices — collection

  def test_returns_one_entry_per_stock
    seed_market

    tickers = recent_prices.to_a.map { |row| row[:ticker] }

    assert_equal %w[aapl bare], tickers.sort
  end

  def test_includes_stock_metadata
    seed_market

    aapl = recent_prices.to_a.find { |row| row[:ticker] == 'aapl' }

    assert_equal 'Apple Inc', aapl[:name]
    assert_equal 'fmp', aapl[:source]
  end

  def test_limits_rows_to_the_most_recent_n
    seed_market

    aapl = recent_prices(limit: 2).to_a.find { |row| row[:ticker] == 'aapl' }

    assert_equal 2, aapl[:rows].size
    assert_equal(%w[2024-01-04 2024-01-05], aapl[:rows].map { |r| r['timestamp'] })
  end

  def test_keeps_ascending_order_within_the_limited_window
    seed_market

    aapl = recent_prices(limit: 3).to_a.find { |row| row[:ticker] == 'aapl' }

    assert_equal(aapl[:rows].map { |r| r['timestamp'] }.sort, aapl[:rows].map { |r| r['timestamp'] })
  end

  def test_a_stock_with_no_prices_reports_an_empty_row_set
    seed_market

    bare = recent_prices.to_a.find { |row| row[:ticker] == 'bare' }

    assert_empty bare[:rows]
  end

  def test_ticker_option_restricts_to_a_single_stock
    seed_market

    tickers = recent_prices(ticker: 'aapl').to_a.map { |row| row[:ticker] }

    assert_equal %w[aapl], tickers
  end

  def test_unknown_ticker_option_returns_nothing
    seed_market

    assert_empty recent_prices(ticker: 'nope').to_a
  end

  #############################################
  ## RecentPricesReport — rendering

  def test_missing_database_renders_without_raising
    report = SQA::RecentPricesReport.new(recent_prices.to_a).to_s

    assert_match(/No stocks found/, report)
  end

  def test_report_includes_ticker_and_name
    seed_market
    report = SQA::RecentPricesReport.new(recent_prices(ticker: 'aapl').to_a).to_s

    assert_match(/AAPL/, report)
    assert_match(/Apple Inc/, report)
  end

  def test_report_includes_every_price_row
    seed_market
    report = SQA::RecentPricesReport.new(recent_prices(ticker: 'aapl').to_a).to_s

    (1..5).each { |d| assert_match(/2024-01-0#{d}/, report) }
  end

  def test_report_notes_stocks_with_no_price_data
    seed_market
    report = SQA::RecentPricesReport.new(recent_prices(ticker: 'bare').to_a).to_s

    assert_match(/no price data/, report)
  end

  def test_report_computes_period_change
    seed_market
    report = SQA::RecentPricesReport.new(recent_prices(ticker: 'aapl').to_a).to_s

    # close goes from 101.0 (day 1) to 105.0 (day 5): +3.96%
    assert_match(/\+3\.96%/, report)
  end

  def test_color_defaults_off_and_can_be_forced_on
    seed_market
    tickers = recent_prices(ticker: 'aapl').to_a

    plain   = SQA::RecentPricesReport.new(tickers, color: false).to_s
    colored = SQA::RecentPricesReport.new(tickers, color: true).to_s

    refute_match(/\e\[/, plain)
    assert_match(/\e\[/, colored)
  end
end
