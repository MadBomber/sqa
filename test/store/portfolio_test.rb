# test/store/portfolio_test.rb
# frozen_string_literal: true

require_relative '../test_helper'
require 'tmpdir'

class StorePortfolioTest < Minitest::Test
  def setup
    @dir   = Dir.mktmpdir('sqa-portfolio-store')
    @store = SQA::Store::Portfolio.new(File.join(@dir, 'portfolio.db'))
  end

  def teardown
    @store.close
    FileUtils.remove_entry(@dir)
  end

  def real_portfolio(name: 'Roth IRA', cash: 10_000.0, commission: 0.0)
    @store.create_portfolio(name:, kind: 'real', initial_cash: cash, commission:)
  end

  def simulated(name: 'RSI Experiment', cash: 10_000.0)
    @store.create_portfolio(name:, kind: 'simulated', initial_cash: cash)
  end

  def watchlist(name: 'Dividend Watch')
    @store.create_portfolio(name:, kind: 'watchlist')
  end

  #############################################
  ## Schema and creation

  def test_migrations_establish_schema_version
    assert_equal 1, @store.schema_version
  end

  def test_create_portfolio_records_each_kind
    real_portfolio
    simulated
    watchlist

    assert_equal %w[real simulated watchlist], @store.portfolios.map { |p| p['kind'] }.sort
  end

  def test_unknown_kind_is_rejected
    error = assert_raises(SQA::BadParameterError) { @store.create_portfolio(name: 'X', kind: 'pretend') }
    assert_match(/Unknown portfolio kind/, error.message)
  end

  def test_watchlist_ignores_initial_cash
    id = @store.create_portfolio(name: 'Watch', kind: 'watchlist', initial_cash: 5_000.0)

    assert_in_delta 0.0, @store.portfolio_by_id(id)['cash']
  end

  def test_portfolios_can_be_filtered_by_kind
    real_portfolio
    watchlist

    assert_equal(['Dividend Watch'], @store.portfolios(kind: 'watchlist').map { |p| p['name'] })
  end

  #############################################
  ## Trades, positions, cash

  def test_buy_creates_position_and_debits_cash
    id = real_portfolio(cash: 10_000.0, commission: 1.0)
    @store.record_trade(portfolio_id: id, ticker: 'AAPL', action: 'buy', shares: 10, price: 150.0)

    position = @store.position(id, 'aapl')

    assert_in_delta 10.0,   position['shares']
    assert_in_delta 150.0,  position['avg_cost']
    assert_in_delta 1500.0, position['total_cost']
    assert_in_delta 8_499.0, @store.portfolio_by_id(id)['cash'], 0.001
  end

  def test_second_buy_averages_the_cost_basis
    id = simulated
    @store.record_trade(portfolio_id: id, ticker: 'aapl', action: 'buy', shares: 10, price: 100.0)
    @store.record_trade(portfolio_id: id, ticker: 'aapl', action: 'buy', shares: 10, price: 200.0)

    position = @store.position(id, 'aapl')

    assert_in_delta 20.0,    position['shares']
    assert_in_delta 150.0,   position['avg_cost']
    assert_in_delta 3_000.0, position['total_cost']
  end

  def test_partial_sale_keeps_avg_cost_and_shrinks_basis
    id = simulated
    @store.record_trade(portfolio_id: id, ticker: 'aapl', action: 'buy', shares: 100, price: 150.0)
    @store.record_trade(portfolio_id: id, ticker: 'aapl', action: 'sell', shares: 50, price: 160.0)

    position = @store.position(id, 'aapl')

    assert_in_delta 50.0,    position['shares']
    assert_in_delta 150.0,   position['avg_cost'], 0.001, 'a partial sale must not move average cost'
    assert_in_delta 7_500.0, position['total_cost']
  end

  def test_full_sale_removes_the_position_and_credits_cash
    id = simulated(cash: 10_000.0)
    @store.record_trade(portfolio_id: id, ticker: 'aapl', action: 'buy', shares: 10, price: 100.0)
    @store.record_trade(portfolio_id: id, ticker: 'aapl', action: 'sell', shares: 10, price: 120.0)

    assert_nil @store.position(id, 'aapl')
    assert_in_delta 10_200.0, @store.portfolio_by_id(id)['cash'], 0.001
  end

  def test_open_establishes_basis_without_moving_cash
    id = real_portfolio(cash: 10_000.0)
    @store.record_trade(portfolio_id: id, ticker: 'aapl', action: 'open', shares: 10, price: 150.0)

    assert_in_delta 10.0,     @store.position(id, 'aapl')['shares']
    assert_in_delta 10_000.0, @store.portfolio_by_id(id)['cash'], 0.001,
                    'open represents shares already held, not shares bought'
  end

  def test_overselling_is_rejected
    id = simulated
    @store.record_trade(portfolio_id: id, ticker: 'aapl', action: 'buy', shares: 5, price: 100.0)

    error = assert_raises(SQA::BadParameterError) do
      @store.record_trade(portfolio_id: id, ticker: 'aapl', action: 'sell', shares: 10, price: 100.0)
    end
    assert_match(/Insufficient shares/, error.message)
  end

  def test_selling_an_unheld_stock_is_rejected
    id = simulated
    assert_raises(SQA::BadParameterError) do
      @store.record_trade(portfolio_id: id, ticker: 'msft', action: 'sell', shares: 1, price: 10.0)
    end
  end

  def test_non_positive_quantities_are_rejected
    id = simulated

    assert_raises(SQA::BadParameterError) { @store.record_trade(portfolio_id: id, ticker: 'a', action: 'buy', shares: 0, price: 10.0) }
    assert_raises(SQA::BadParameterError) { @store.record_trade(portfolio_id: id, ticker: 'a', action: 'buy', shares: 1, price: 0.0) }
  end

  def test_unknown_action_is_rejected
    id = simulated
    assert_raises(SQA::BadParameterError) { @store.record_trade(portfolio_id: id, ticker: 'a', action: 'short', shares: 1, price: 10.0) }
  end

  def test_fractional_shares_are_supported
    id = simulated
    @store.record_trade(portfolio_id: id, ticker: 'aapl', action: 'buy', shares: 0.5, price: 100.0)

    assert_in_delta 0.5, @store.position(id, 'aapl')['shares']
  end

  def test_failed_trade_leaves_no_partial_record
    id = simulated
    @store.record_trade(portfolio_id: id, ticker: 'aapl', action: 'buy', shares: 5, price: 100.0)
    cash_before = @store.portfolio_by_id(id)['cash']

    assert_raises(SQA::BadParameterError) do
      @store.record_trade(portfolio_id: id, ticker: 'aapl', action: 'sell', shares: 99, price: 100.0)
    end

    assert_equal 1, @store.trades(id).size, 'the rejected trade must not have been inserted'
    assert_in_delta cash_before, @store.portfolio_by_id(id)['cash'], 0.001
  end

  def test_rebuild_positions_reproduces_the_materialized_view
    id = simulated
    @store.record_trade(portfolio_id: id, ticker: 'aapl', action: 'buy', shares: 10, price: 100.0)
    @store.record_trade(portfolio_id: id, ticker: 'msft', action: 'buy', shares: 5,  price: 200.0)
    @store.record_trade(portfolio_id: id, ticker: 'aapl', action: 'sell', shares: 4, price: 120.0)

    before = @store.positions(id)
    assert_equal 2, @store.rebuild_positions!(id)
    assert_equal before.map { |p| p.except('updated_at') },
                 @store.positions(id).map { |p| p.except('updated_at') },
                 'positions must be derivable from trades alone'
  end

  #############################################
  ## Cost-basis arithmetic (pure -- no database)

  def fill(action, shares, price, ticker: 'aapl', date: '2024-01-01')
    SQA::Store::Portfolio::Fill.new(ticker:, action:, shares:, price:, total: shares * price, date:)
  end

  def holding(shares, avg_cost, total_cost, ticker: 'aapl', opened_on: '2024-01-01')
    SQA::Store::Portfolio::Holding.new(ticker:, shares:, avg_cost:, total_cost:, opened_on:)
  end

  def test_increase_establishes_basis_on_a_first_purchase
    result = SQA::Store::Portfolio.increase(fill('buy', 10.0, 150.0), nil)

    assert_in_delta 10.0,   result.shares
    assert_in_delta 150.0,  result.avg_cost
    assert_in_delta 1500.0, result.total_cost
  end

  def test_increase_averages_into_an_existing_basis
    result = SQA::Store::Portfolio.increase(fill('buy', 10.0, 200.0), holding(10.0, 100.0, 1_000.0))

    assert_in_delta 20.0,    result.shares
    assert_in_delta 150.0,   result.avg_cost
    assert_in_delta 3_000.0, result.total_cost
  end

  def test_increase_preserves_the_original_open_date
    result = SQA::Store::Portfolio.increase(fill('buy', 1.0, 10.0, date: '2024-06-01'),
                                            holding(1.0, 10.0, 10.0, opened_on: '2020-01-01'))

    assert_equal '2020-01-01', result.opened_on, 'adding to a position does not reopen it'
  end

  def test_decrease_returns_nil_when_the_position_closes
    assert_nil SQA::Store::Portfolio.decrease(fill('sell', 10.0, 160.0), holding(10.0, 150.0, 1_500.0))
  end

  def test_decrease_shrinks_basis_without_moving_average_cost
    result = SQA::Store::Portfolio.decrease(fill('sell', 50.0, 160.0), holding(100.0, 150.0, 15_000.0))

    assert_in_delta 50.0,    result.shares
    assert_in_delta 150.0,   result.avg_cost, 0.001
    assert_in_delta 7_500.0, result.total_cost
  end

  def test_decrease_rejects_selling_more_than_held
    assert_raises(SQA::BadParameterError) do
      SQA::Store::Portfolio.decrease(fill('sell', 11.0, 160.0), holding(10.0, 150.0, 1_500.0))
    end
  end

  def test_decrease_rejects_selling_nothing_held
    assert_raises(SQA::BadParameterError) { SQA::Store::Portfolio.decrease(fill('sell', 1.0, 10.0), nil) }
  end

  def test_holding_from_row_maps_a_positions_row
    result = SQA::Store::Portfolio::Holding.from_row(
      { 'ticker' => 'ko', 'shares' => 2.0, 'avg_cost' => 60.0, 'total_cost' => 120.0, 'opened_on' => '2024-01-01' }
    )

    assert_equal 'ko', result.ticker
    assert_in_delta 120.0, result.total_cost
  end

  def test_holding_from_row_is_nil_when_nothing_is_held
    assert_nil SQA::Store::Portfolio::Holding.from_row(nil)
  end

  #############################################
  ## Watchlists

  def test_watchlist_admits_members_at_equal_notional
    id = watchlist
    @store.watch(id, ticker: 'ko',   price: 62.50)
    @store.watch(id, ticker: 'brka', price: 500.00)

    ko   = @store.position(id, 'ko')
    brka = @store.position(id, 'brka')

    assert_in_delta 16.0, ko['shares']
    assert_in_delta 2.0,  brka['shares']
    assert_in_delta ko['total_cost'], brka['total_cost'], 0.001,
                    'equal notional keeps a $500 stock comparable to a $62 one'
  end

  def test_watchlist_rejects_buying_and_selling
    id = watchlist

    error = assert_raises(SQA::BadParameterError) do
      @store.record_trade(portfolio_id: id, ticker: 'ko', action: 'buy', shares: 1, price: 10.0)
    end
    assert_match(/cannot buy/, error.message)
  end

  #############################################
  ## Valuations

  def test_valuations_form_an_equity_curve
    id = simulated
    @store.record_valuation(portfolio_id: id, cash: 100.0, positions_value: 900.0,  valued_on: '2024-01-01')
    @store.record_valuation(portfolio_id: id, cash: 100.0, positions_value: 1000.0, valued_on: '2024-01-02')

    curve = @store.valuations(id)

    assert_equal(%w[2024-01-01 2024-01-02], curve.map { |v| v['valued_on'] })
    assert_in_delta 1_100.0, curve.last['total_value']
  end

  def test_revaluing_the_same_date_overwrites
    id = simulated
    @store.record_valuation(portfolio_id: id, cash: 0.0, positions_value: 1.0, valued_on: '2024-01-01')
    @store.record_valuation(portfolio_id: id, cash: 0.0, positions_value: 2.0, valued_on: '2024-01-01')

    assert_equal 1, @store.valuations(id).size
    assert_in_delta 2.0, @store.valuations(id).first['total_value']
  end

  #############################################
  ## Editing

  def test_update_portfolio_edits_whitelisted_attributes
    id = real_portfolio
    updated = @store.update_portfolio(id, name: 'Roth IRA (Fidelity)', broker: 'Fidelity')

    assert_equal 'Roth IRA (Fidelity)', updated['name']
    assert_equal 'Fidelity',            updated['broker']
  end

  def test_update_portfolio_refuses_derived_attributes
    id = real_portfolio

    error = assert_raises(SQA::BadParameterError) { @store.update_portfolio(id, cash: 999.0) }
    assert_match(/Cannot edit cash/, error.message)
  end

  def test_kind_can_be_changed_when_history_allows
    id = @store.create_portfolio(name: 'Ideas', kind: 'simulated')
    @store.record_trade(portfolio_id: id, ticker: 'ko', action: 'open', shares: 1, price: 60.0)

    assert_equal 'watchlist', @store.update_portfolio(id, kind: 'watchlist')['kind']
  end

  def test_converting_a_traded_portfolio_to_a_watchlist_is_refused
    id = simulated
    @store.record_trade(portfolio_id: id, ticker: 'aapl', action: 'buy', shares: 1, price: 100.0)

    error = assert_raises(SQA::BadParameterError) { @store.update_portfolio(id, kind: 'watchlist') }
    assert_match(/Copy it instead/, error.message)
  end

  #############################################
  ## Copying

  def test_copy_watchlist_into_simulated_carries_members_as_positions
    source = watchlist
    @store.watch(source, ticker: 'ko', price: 62.50)

    copy = @store.copy_portfolio(source, as: 'Dividend Sim', kind: 'simulated', initial_cash: 5_000.0)
    record = @store.portfolio_by_id(copy)

    assert_equal 'simulated', record['kind']
    assert_in_delta 5_000.0,  record['cash'], 0.001, 'open rows must not spend the new cash'
    assert_in_delta 16.0,     @store.position(copy, 'ko')['shares']
  end

  def test_copy_simulated_into_real_defaults_to_positions_only
    source = simulated
    @store.record_trade(portfolio_id: source, ticker: 'aapl', action: 'buy', shares: 10, price: 100.0)
    @store.record_trade(portfolio_id: source, ticker: 'aapl', action: 'buy', shares: 10, price: 200.0)

    copy = @store.copy_portfolio(source, as: 'Live Account', kind: 'real')
    trades = @store.trades(copy)

    assert_equal 1,      trades.size, 'a real portfolio must not inherit trades that never happened'
    assert_equal 'open', trades.first['action']
    assert_in_delta 20.0,  @store.position(copy, 'aapl')['shares']
    assert_in_delta 150.0, @store.position(copy, 'aapl')['avg_cost'], 0.001, 'cost basis carries across'
  end

  def test_copy_into_real_can_opt_into_full_history
    source = simulated
    @store.record_trade(portfolio_id: source, ticker: 'aapl', action: 'buy', shares: 10, price: 100.0)
    @store.record_trade(portfolio_id: source, ticker: 'aapl', action: 'sell', shares: 4, price: 120.0)

    copy = @store.copy_portfolio(source, as: 'Live', kind: 'real', history: :trades)

    assert_equal 2, @store.trades(copy).size
    assert_in_delta 6.0, @store.position(copy, 'aapl')['shares']
  end

  def test_copy_real_into_simulated_replays_full_history
    source = real_portfolio(cash: 10_000.0)
    @store.record_trade(portfolio_id: source, ticker: 'aapl', action: 'buy', shares: 10, price: 100.0)

    copy = @store.copy_portfolio(source, as: 'Sandbox', kind: 'simulated')

    assert_equal 1, @store.trades(copy).size
    assert_in_delta @store.portfolio_by_id(source)['cash'], @store.portfolio_by_id(copy)['cash'], 0.001
  end

  def test_copy_into_watchlist_takes_holdings_only
    source = simulated
    @store.record_trade(portfolio_id: source, ticker: 'aapl', action: 'buy', shares: 10, price: 100.0)

    copy = @store.copy_portfolio(source, as: 'Just Watching', kind: 'watchlist')

    assert_equal(%w[open], @store.trades(copy).map { |t| t['action'] })
    assert_in_delta 10.0,  @store.position(copy, 'aapl')['shares']
  end

  def test_copy_into_watchlist_rejects_an_explicit_trades_request
    source = simulated

    error = assert_raises(SQA::BadParameterError) do
      @store.copy_portfolio(source, as: 'W', kind: 'watchlist', history: :trades)
    end
    assert_match(/watchlist holds no trades/, error.message)
  end

  def test_copy_rejects_a_duplicate_name
    source = simulated
    real_portfolio(name: 'Taken')

    assert_raises(SQA::BadParameterError) { @store.copy_portfolio(source, as: 'Taken') }
  end

  def test_copy_leaves_the_source_untouched
    source = simulated
    @store.record_trade(portfolio_id: source, ticker: 'aapl', action: 'buy', shares: 10, price: 100.0)
    before = @store.portfolio_by_id(source)

    @store.copy_portfolio(source, as: 'Copy')

    assert_equal before['cash'], @store.portfolio_by_id(source)['cash']
    assert_equal 1, @store.trades(source).size
  end

  #############################################
  ## Bridging to SQA::Portfolio

  def in_memory
    portfolio = SQA::Portfolio.new(initial_cash: 10_000.0, commission: 1.0)
    portfolio.buy('aapl', shares: 10, price: 150.0, date: Date.new(2024, 1, 1))
    portfolio.sell('aapl', shares: 4, price: 160.0, date: Date.new(2024, 2, 1))
    portfolio
  end

  def test_save_portfolio_persists_trades_and_positions
    id = @store.save_portfolio(in_memory, as: 'Strategy Run')

    assert_equal(%w[buy sell], @store.trades(id).map { |t| t['action'] })
    assert_in_delta 6.0, @store.position(id, 'aapl')['shares']
  end

  def test_save_and_load_round_trips_cash_and_positions
    source = in_memory
    @store.save_portfolio(source, as: 'Strategy Run')
    restored = @store.load_portfolio('Strategy Run')

    assert_in_delta source.cash,         restored.cash, 0.001
    assert_in_delta source.initial_cash, restored.initial_cash, 0.001
    assert_in_delta source.commission,   restored.commission, 0.001
    assert_in_delta source.position('aapl').shares,   restored.position('aapl').shares
    assert_in_delta source.position('aapl').avg_cost, restored.position('aapl').avg_cost, 0.001
    assert_equal    source.trades.size,  restored.trades.size
  end

  def test_round_trip_preserves_valuation_that_the_legacy_csv_lost
    source = in_memory
    @store.save_portfolio(source, as: 'Strategy Run')
    restored = @store.load_portfolio('Strategy Run')

    assert_in_delta source.value('aapl' => 170.0), restored.value('aapl' => 170.0), 0.001,
                    'save_to_csv dropped cash entirely, making a reloaded valuation wrong'
    refute_in_delta 0.0, restored.initial_cash, 0.001, 'load_from_csv used to hardcode initial_cash to 0'
  end

  def test_restored_trades_carry_symbol_actions
    @store.save_portfolio(in_memory, as: 'Strategy Run')

    assert_equal %i[buy sell], @store.load_portfolio('Strategy Run').trades.map(&:action)
  end

  def test_a_positions_only_portfolio_saves_as_open_rows
    source = SQA::Portfolio.new(initial_cash: 0)
    source.positions['aapl'] = SQA::Portfolio::Position.new('aapl', 10.0, 150.0, 1_500.0)

    id = @store.save_portfolio(source, as: 'Imported', kind: 'real')

    assert_equal(%w[open], @store.trades(id).map { |t| t['action'] })
    assert_in_delta 10.0, @store.position(id, 'aapl')['shares']
  end

  def test_save_refuses_to_clobber_without_replace
    @store.save_portfolio(in_memory, as: 'Strategy Run')

    error = assert_raises(SQA::BadParameterError) { @store.save_portfolio(in_memory, as: 'Strategy Run') }
    assert_match(/pass replace: true/, error.message)
  end

  def test_save_with_replace_overwrites_cleanly
    @store.save_portfolio(in_memory, as: 'Strategy Run')

    fresh = SQA::Portfolio.new(initial_cash: 500.0)
    fresh.buy('msft', shares: 1, price: 100.0)
    id = @store.save_portfolio(fresh, as: 'Strategy Run', replace: true)

    assert_equal 1, @store.portfolios.size, 'replace must not leave an orphan behind'
    assert_equal(%w[msft], @store.positions(id).map { |p| p['ticker'] })
  end

  def test_loading_an_unknown_portfolio_raises
    assert_raises(SQA::BadParameterError) { @store.load_portfolio('nope') }
  end

  #############################################
  ## Import / export / backup

  def test_export_is_self_describing
    id = simulated
    @store.record_trade(portfolio_id: id, ticker: 'aapl', action: 'buy', shares: 10, price: 100.0)

    document = @store.export_portfolio(id)

    assert_equal 'sqa.portfolio', document['format']
    assert_equal 1,               document['version']
    assert_equal 'RSI Experiment', document['portfolio']['name']
    assert_equal 1, document['trades'].size
    refute document['trades'].first.key?('portfolio_id'), 'ids must not leak into a portable document'
  end

  def test_export_and_import_round_trip
    id = simulated
    @store.record_trade(portfolio_id: id, ticker: 'aapl', action: 'buy', shares: 10, price: 100.0)
    @store.record_trade(portfolio_id: id, ticker: 'msft', action: 'buy', shares: 5,  price: 200.0)
    @store.record_valuation(portfolio_id: id, cash: 8_000.0, positions_value: 2_000.0, valued_on: '2024-01-01')

    path     = @store.export_portfolio_to_file(id, File.join(@dir, 'export.json'))
    restored = @store.import_portfolio(path, as: 'Restored')

    assert_equal 2, @store.trades(restored).size
    assert_equal 2, @store.positions(restored).size
    assert_equal 1, @store.valuations(restored).size
    assert_in_delta @store.portfolio_by_id(id)['cash'], @store.portfolio_by_id(restored)['cash'], 0.001
  end

  def test_import_can_rekind
    id = simulated
    @store.record_trade(portfolio_id: id, ticker: 'aapl', action: 'buy', shares: 10, price: 100.0)
    document = @store.export_portfolio(id)

    restored = @store.import_portfolio(document, as: 'Watching It', kind: 'watchlist')

    assert_equal 'watchlist', @store.portfolio_by_id(restored)['kind']
    assert_equal(%w[open],    @store.trades(restored).map { |t| t['action'] })
  end

  def test_import_rejects_a_foreign_json_document
    path = File.join(@dir, 'yahoo.json')
    File.write(path, JSON.generate({ 'summary' => {}, 'chart' => {} }))

    error = assert_raises(SQA::BadParameterError) { @store.import_portfolio(path) }
    assert_match(/Not an SQA portfolio export/, error.message)
  end

  def test_import_rejects_an_unsupported_version
    document = @store.export_portfolio(simulated).merge('version' => 99)

    error = assert_raises(SQA::BadParameterError) { @store.import_portfolio(document, as: 'X') }
    assert_match(/Unsupported export version/, error.message)
  end

  def test_import_rejects_a_name_clash
    id = simulated
    document = @store.export_portfolio(id)

    error = assert_raises(SQA::BadParameterError) { @store.import_portfolio(document) }
    assert_match(/already exists; pass as:/, error.message)
  end

  def test_backup_writes_a_timestamped_file
    id = real_portfolio(name: 'Roth IRA')
    path = @store.backup_portfolio(id, @dir, at: Time.utc(2024, 3, 1, 12, 30, 45))

    assert_equal 'roth-ira-20240301T123045Z.json', path.basename.to_s
    assert_equal 'sqa.portfolio', JSON.parse(path.read)['format']
  end

  def test_deleting_a_portfolio_cascades
    id = simulated
    @store.record_trade(portfolio_id: id, ticker: 'aapl', action: 'buy', shares: 1, price: 10.0)
    @store.record_valuation(portfolio_id: id, cash: 1.0, positions_value: 1.0)

    assert_equal 1, @store.delete_portfolio(id)
    assert_empty @store.trades(id)
    assert_empty @store.positions(id)
    assert_empty @store.valuations(id)
  end
end
