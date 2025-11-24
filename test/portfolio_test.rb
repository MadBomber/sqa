require_relative 'test_helper'

class PortfolioTest < Minitest::Test
  def setup
    @portfolio = SQA::Portfolio.new(initial_cash: 10_000.0, commission: 1.0)
  end

  def test_initialization
    assert_equal 10_000.0, @portfolio.cash
    assert_equal 10_000.0, @portfolio.initial_cash
    assert_equal 1.0, @portfolio.commission
    assert_empty @portfolio.positions
    assert_empty @portfolio.trades
  end

  def test_buy_creates_position
    @portfolio.buy('AAPL', shares: 10, price: 150.0, date: Date.today)

    assert_equal 1, @portfolio.positions.size
    assert @portfolio.positions.key?('AAPL')

    position = @portfolio.positions['AAPL']
    assert_equal 10, position.shares
    assert_equal 150.0, position.avg_cost
    # total_cost is pure share cost, commission tracked separately on trades
    assert_equal 1_500.0, position.total_cost # 10 * 150
  end

  def test_buy_updates_cash
    initial_cash = @portfolio.cash
    @portfolio.buy('AAPL', shares: 10, price: 150.0, date: Date.today)

    expected_cash = initial_cash - (10 * 150.0) - 1.0
    assert_equal expected_cash, @portfolio.cash
  end

  def test_buy_multiple_times_averages_cost
    @portfolio.buy('AAPL', shares: 10, price: 150.0, date: Date.today)
    @portfolio.buy('AAPL', shares: 10, price: 160.0, date: Date.today)

    position = @portfolio.positions['AAPL']
    assert_equal 20, position.shares
    # Average cost: (10*150 + 10*160) / 20 = 155
    assert_in_delta 155.0, position.avg_cost, 0.01
  end

  def test_sell_reduces_position
    @portfolio.buy('AAPL', shares: 20, price: 150.0, date: Date.today)
    @portfolio.sell('AAPL', shares: 10, price: 160.0, date: Date.today)

    position = @portfolio.positions['AAPL']
    assert_equal 10, position.shares
  end

  def test_sell_removes_position_when_all_sold
    @portfolio.buy('AAPL', shares: 10, price: 150.0, date: Date.today)
    @portfolio.sell('AAPL', shares: 10, price: 160.0, date: Date.today)

    refute @portfolio.positions.key?('AAPL')
  end

  def test_sell_increases_cash
    @portfolio.buy('AAPL', shares: 10, price: 150.0, date: Date.today)
    cash_before_sell = @portfolio.cash

    @portfolio.sell('AAPL', shares: 10, price: 160.0, date: Date.today)

    expected_cash = cash_before_sell + (10 * 160.0) - 1.0
    assert_equal expected_cash, @portfolio.cash
  end

  def test_trades_recorded
    @portfolio.buy('AAPL', shares: 10, price: 150.0, date: Date.today)
    @portfolio.sell('AAPL', shares: 5, price: 160.0, date: Date.today)

    assert_equal 2, @portfolio.trades.size

    buy_trade = @portfolio.trades.first
    assert_equal :buy, buy_trade.action
    assert_equal 10, buy_trade.shares
    assert_equal 150.0, buy_trade.price

    sell_trade = @portfolio.trades.last
    assert_equal :sell, sell_trade.action
    assert_equal 5, sell_trade.shares
    assert_equal 160.0, sell_trade.price
  end

  def test_value_calculation
    @portfolio.buy('AAPL', shares: 10, price: 150.0, date: Date.today)

    current_prices = { 'AAPL' => 160.0 }
    value = @portfolio.value(current_prices)

    expected_value = @portfolio.cash + (10 * 160.0)
    assert_equal expected_value, value
  end

  def test_profit_loss_calculation
    @portfolio.buy('AAPL', shares: 10, price: 150.0, date: Date.today)

    current_prices = { 'AAPL' => 160.0 }
    pl = @portfolio.profit_loss(current_prices)

    # P&L = current_value - initial_cash
    # Cash after buy: 10000 - (10*150 + 1 commission) = 8499
    # Position value: 10 * 160 = 1600
    # Total value: 8499 + 1600 = 10099
    # P&L: 10099 - 10000 = 99
    expected_pl = 99.0
    assert_in_delta expected_pl, pl, 0.01
  end

  def test_summary
    @portfolio.buy('AAPL', shares: 10, price: 150.0, date: Date.today)
    @portfolio.buy('MSFT', shares: 5, price: 200.0, date: Date.today)

    summary = @portfolio.summary

    assert_equal 10_000.0, summary[:initial_cash]
    assert summary[:current_cash] < 10_000.0
    assert_equal 2, summary[:positions_count]
    assert_equal 2, summary[:total_trades]
  end

  def test_commission_applied
    @portfolio.buy('AAPL', shares: 10, price: 100.0, date: Date.today)

    # Should have spent: 10 * 100 + 1 commission = 1001
    expected_cash = 10_000.0 - 1_001.0
    assert_equal expected_cash, @portfolio.cash
  end

  def test_zero_commission
    portfolio = SQA::Portfolio.new(initial_cash: 10_000.0, commission: 0.0)
    portfolio.buy('AAPL', shares: 10, price: 100.0, date: Date.today)

    # Should have spent exactly: 10 * 100 = 1000
    expected_cash = 10_000.0 - 1_000.0
    assert_equal expected_cash, portfolio.cash
  end
end
