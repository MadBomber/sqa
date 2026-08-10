# test/summary_test.rb
# frozen_string_literal: true

require_relative 'test_helper'
require 'tmpdir'

# bin/sqa-summary has no .rb extension (matching bin/sqa-console), so
# require_relative cannot find it by name. Loading it defines SQA::Summary and
# SQA::SummaryReport without running the CLI, which is guarded by
# $PROGRAM_NAME == __FILE__.
load File.expand_path('../bin/sqa-summary', __dir__)

class SummaryTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir('sqa-summary')
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def summary(today: Date.new(2024, 1, 10)) = SQA::Summary.new(data_dir: @dir, today:)

  def seed_market
    store = SQA::Store::Market.new(File.join(@dir, 'sqa.db'))
    store.save_stock(ticker: 'aapl', source: :fmp, name: 'Apple Inc')
    store.save_prices('aapl', [
                        { 'timestamp' => '2024-01-08', 'close_price' => 100.0, 'adj_close_price' => 100.0 },
                        { 'timestamp' => '2024-01-09', 'close_price' => 110.0, 'adj_close_price' => 110.0 }
                      ])
    store.save_stock(ticker: 'old', source: :fmp)
    store.save_prices('old', [{ 'timestamp' => '2020-01-01', 'close_price' => 5.0, 'adj_close_price' => 5.0 }])
    store.save_stock(ticker: 'bare', source: :fmp)
    store.replace_tickers([{ symbol: 'AAPL', name: 'Apple', exchange: 'NASDAQ' }])
    store.close
  end

  def seed_portfolio
    store = SQA::Store::Portfolio.new(File.join(@dir, 'portfolio.db'))
    id = store.create_portfolio(name: 'Test Fund', kind: 'simulated', initial_cash: 10_000.0)
    store.record_trade(portfolio_id: id, ticker: 'aapl', action: 'buy', shares: 10, price: 90.0)
    store.record_trade(portfolio_id: id, ticker: 'ghost', action: 'buy', shares: 5, price: 20.0)
    store.close
    id
  end

  #############################################
  ## Read-only guarantee

  def test_summarizing_does_not_create_databases
    result = summary.to_h

    assert result[:market][:missing]
    assert result[:portfolios][:missing]
    refute File.exist?(File.join(@dir, 'sqa.db')),      'a summary must not bring sqa.db into existence'
    refute File.exist?(File.join(@dir, 'portfolio.db')), 'a summary must not bring portfolio.db into existence'
  end

  def test_missing_databases_render_without_raising
    report = SQA::SummaryReport.new(summary.to_h).to_s

    assert_match(/not present/, report)
    refute_match(/schema v/, report)
  end

  #############################################
  ## Market

  def test_market_summary_counts_stocks_and_rows
    seed_market
    market = summary.summarize_market

    refute market[:missing]
    assert_equal 3, market[:stocks].size
    assert_equal 3, market[:rows]
    assert_equal 1, market[:tickers]
    assert_equal 1, market[:schema]
  end

  def test_market_summary_reports_overall_coverage
    seed_market
    market = summary.summarize_market

    assert_equal '2020-01-01', market[:first]
    assert_equal '2024-01-09', market[:last]
  end

  def test_market_summary_classifies_each_stock
    seed_market

    assert_equal({ current: 1, stale: 1, empty: 1 }, summary.summarize_market[:counts])
  end

  def test_status_for_boundaries
    subject = summary(today: Date.new(2024, 1, 10))

    assert_equal :empty,   subject.status_for(nil)
    assert_equal :current, subject.status_for('2024-01-10')
    assert_equal :current, subject.status_for('2024-01-06'), '4 days back clears a weekend'
    assert_equal :stale,   subject.status_for('2024-01-05')
  end

  def test_latest_closes_returns_the_final_adjusted_close
    seed_market

    assert_in_delta 110.0, summary.latest_closes['aapl']
  end

  def test_latest_closes_omits_tickers_without_prices
    seed_market

    refute summary.latest_closes.key?('bare')
  end

  def test_latest_closes_is_empty_without_a_market_database
    assert_empty summary.latest_closes
  end

  #############################################
  ## Portfolios

  def test_portfolio_summary_values_positions_at_the_latest_close
    seed_market
    seed_portfolio

    item = summary.summarize_portfolios[:items].first

    assert_equal 'Test Fund', item[:name]
    assert_equal 2, item[:positions]
    assert_in_delta 1_100.0, item[:value], 0.001, '10 aapl at the 110.00 close'
  end

  def test_portfolio_summary_flags_positions_with_no_price_data
    seed_market
    seed_portfolio

    assert_equal ['ghost'], summary.summarize_portfolios[:items].first[:unpriced]
  end

  def test_unpriced_positions_are_reported_rather_than_valued_at_zero
    seed_market
    seed_portfolio
    report = SQA::SummaryReport.new(summary.to_h).to_s

    assert_match(/Not valued \(no price data in sqa\.db\)/, report)
    assert_match(/Test Fund: ghost/, report)
  end

  def test_portfolio_summary_counts_by_kind
    seed_market
    store = SQA::Store::Portfolio.new(File.join(@dir, 'portfolio.db'))
    store.create_portfolio(name: 'A', kind: 'real')
    store.create_portfolio(name: 'B', kind: 'watchlist')
    store.create_portfolio(name: 'C', kind: 'watchlist')
    store.close

    assert_equal({ 'real' => 1, 'watchlist' => 2 }, summary.summarize_portfolios[:counts])
  end

  #############################################
  ## Rendering

  def test_report_scales_byte_sizes_correctly
    report = SQA::SummaryReport.new({})

    assert_equal '512 B',   report.send(:human_bytes, 512)
    assert_equal '1.0 KB',  report.send(:human_bytes, 1024)
    assert_equal '4.9 MB',  report.send(:human_bytes, 5_138_432), 'megabytes must not be reported as gigabytes'
    assert_equal '1.0 GB',  report.send(:human_bytes, 1024**3)
  end

  def test_report_delimits_large_row_counts
    seed_market
    report = SQA::SummaryReport.new(summary.to_h).to_s

    assert_match(/schema v1/, report)
    assert_match(/3 price rows/, report)
  end

  def test_verbose_adds_the_per_ticker_table
    seed_market

    refute_match(/TICKER/, SQA::SummaryReport.new(summary.to_h).to_s)
    assert_match(/TICKER/, SQA::SummaryReport.new(summary.to_h, verbose: true).to_s)
  end

  def test_table_layout_is_independent_of_terminal_width
    seed_market
    seed_portfolio
    report = SQA::SummaryReport.new(summary.to_h, verbose: true).to_s

    # One line per stock plus header and rule -- not transposed into key/value
    # pairs, which is what a width-sensitive renderer does on a narrow terminal.
    assert_equal(1, report.lines.count { |line| line.include?('TICKER') })
    assert(report.lines.any? { |line| line.match?(/aapl\s+2\s+2024-01-08/) })
  end
end
