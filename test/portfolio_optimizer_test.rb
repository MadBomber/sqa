# test/portfolio_optimizer_test.rb
# frozen_string_literal: true

require_relative 'test_helper'

class PortfolioOptimizerTest < Minitest::Test
  def setup
    # Returns for 3 assets over 10 periods
    @returns_matrix = [
      [0.01, -0.02, 0.015, -0.01, 0.005, 0.02, -0.015, 0.01, -0.005, 0.025],  # Asset 1
      [0.02, 0.01, -0.01, 0.005, 0.015, -0.02, 0.01, 0.02, 0.005, -0.01],     # Asset 2
      [-0.01, 0.03, 0.02, 0.01, -0.005, 0.01, 0.005, -0.015, 0.02, 0.01]      # Asset 3
    ]
  end

  def test_portfolio_returns
    weights = [0.4, 0.3, 0.3]
    port_returns = SQA::PortfolioOptimizer.portfolio_returns(@returns_matrix, weights)

    assert_instance_of Array, port_returns
    assert_equal @returns_matrix.first.size, port_returns.size
  end

  def test_portfolio_variance
    weights = [0.4, 0.3, 0.3]
    variance = SQA::PortfolioOptimizer.portfolio_variance(@returns_matrix, weights)

    assert_instance_of Float, variance
    assert variance >= 0
  end

  def test_maximum_sharpe
    result = SQA::PortfolioOptimizer.maximum_sharpe(@returns_matrix, risk_free_rate: 0.02)

    assert_instance_of Hash, result
    assert result.key?(:weights)
    assert result.key?(:sharpe)
    assert result.key?(:return)
    assert result.key?(:volatility)

    # Weights should sum to 1.0
    assert_in_delta 1.0, result[:weights].sum, 0.01
  end

  def test_minimum_variance
    result = SQA::PortfolioOptimizer.minimum_variance(@returns_matrix)

    assert_instance_of Hash, result
    assert result.key?(:weights)
    assert result.key?(:variance)
    assert result.key?(:volatility)

    assert_in_delta 1.0, result[:weights].sum, 0.01
  end

  def test_risk_parity
    result = SQA::PortfolioOptimizer.risk_parity(@returns_matrix)

    assert_instance_of Hash, result
    assert result.key?(:weights)
    assert result.key?(:volatility)

    assert_in_delta 1.0, result[:weights].sum, 0.01
  end

  def test_efficient_frontier
    portfolios = SQA::PortfolioOptimizer.efficient_frontier(@returns_matrix, num_portfolios: 20)

    assert_instance_of Array, portfolios
    assert_equal 20, portfolios.size

    portfolios.each do |p|
      assert p.key?(:weights)
      assert p.key?(:return)
      assert p.key?(:volatility)
      assert p.key?(:sharpe)

      assert_in_delta 1.0, p[:weights].sum, 0.01
    end

    # Should be sorted by volatility
    volatilities = portfolios.map { |p| p[:volatility] }
    assert_equal volatilities.sort, volatilities
  end

  def test_multi_objective
    result = SQA::PortfolioOptimizer.multi_objective(
      @returns_matrix,
      objectives: {
        maximize_return: 0.4,
        minimize_volatility: 0.3,
        minimize_drawdown: 0.3
      }
    )

    assert_instance_of Hash, result
    assert result.key?(:weights)
    assert result.key?(:return)
    assert result.key?(:volatility)
    assert result.key?(:max_drawdown)
    assert result.key?(:composite_score)

    assert_in_delta 1.0, result[:weights].sum, 0.01
  end

  def test_equal_weight
    weights = SQA::PortfolioOptimizer.equal_weight(3)

    assert_equal [1.0/3, 1.0/3, 1.0/3], weights
  end

  def test_rebalance
    current_values = { 'AAPL' => 3000, 'MSFT' => 4000, 'GOOGL' => 3000 }
    target_weights = { 'AAPL' => 0.4, 'MSFT' => 0.3, 'GOOGL' => 0.3 }
    prices = { 'AAPL' => 150.0, 'MSFT' => 200.0, 'GOOGL' => 100.0 }

    trades = SQA::PortfolioOptimizer.rebalance(
      current_values: current_values,
      target_weights: target_weights,
      total_value: 10_000,
      prices: prices
    )

    assert_instance_of Hash, trades
    trades.each do |ticker, trade|
      assert trade.key?(:action)
      assert trade.key?(:shares)
      assert trade.key?(:value)
      assert [:buy, :sell].include?(trade[:action])
    end
  end
end
