require_relative 'test_helper'

class BacktestTest < Minitest::Test
  def setup
    # Skip if we can't load real stock data
    skip "Requires network access for stock data" unless ENV['RUN_INTEGRATION_TESTS']

    SQA.init
    @stock = SQA::Stock.new(ticker: 'AAPL')
  end

  def test_initialization
    skip "Requires network access" unless ENV['RUN_INTEGRATION_TESTS']

    backtest = SQA::Backtest.new(
      stock: @stock,
      strategy: SQA::Strategy::RSI,
      initial_capital: 10_000.0
    )

    assert_equal @stock, backtest.stock
    assert_equal 10_000.0, backtest.initial_capital
  end

  def test_backtest_returns_results
    skip "Requires network access" unless ENV['RUN_INTEGRATION_TESTS']

    backtest = SQA::Backtest.new(
      stock: @stock,
      strategy: SQA::Strategy::RSI,
      initial_capital: 10_000.0
    )

    results = backtest.run

    assert_instance_of SQA::Backtest::Results, results
    assert_respond_to results, :total_return
    assert_respond_to results, :sharpe_ratio
    assert_respond_to results, :max_drawdown
    assert_respond_to results, :total_trades
  end

  def test_backtest_with_proc_strategy
    skip "Requires network access" unless ENV['RUN_INTEGRATION_TESTS']

    simple_strategy = lambda { |vector| :hold }

    backtest = SQA::Backtest.new(
      stock: @stock,
      strategy: simple_strategy,
      initial_capital: 10_000.0
    )

    results = backtest.run

    # Hold strategy should have no trades
    assert_equal 0, results.total_trades
  end

  def test_results_structure
    results = SQA::Backtest::Results.new

    # Verify all expected attributes exist
    assert_respond_to results, :total_return
    assert_respond_to results, :annualized_return
    assert_respond_to results, :sharpe_ratio
    assert_respond_to results, :max_drawdown
    assert_respond_to results, :total_trades
    assert_respond_to results, :winning_trades
    assert_respond_to results, :losing_trades
    assert_respond_to results, :win_rate
    assert_respond_to results, :average_win
    assert_respond_to results, :average_loss
    assert_respond_to results, :profit_factor
  end

  def test_commission_affects_results
    skip "Requires network access" unless ENV['RUN_INTEGRATION_TESTS']

    # Run with no commission
    backtest1 = SQA::Backtest.new(
      stock: @stock,
      strategy: SQA::Strategy::RSI,
      initial_capital: 10_000.0,
      commission: 0.0
    )
    results1 = backtest1.run

    # Run with commission
    backtest2 = SQA::Backtest.new(
      stock: @stock,
      strategy: SQA::Strategy::RSI,
      initial_capital: 10_000.0,
      commission: 10.0
    )
    results2 = backtest2.run

    # Commission should reduce returns (if there are any trades)
    if results1.total_trades > 0
      assert results1.total_return >= results2.total_return
    end
  end
end
