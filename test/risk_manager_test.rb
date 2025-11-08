# test/risk_manager_test.rb
# frozen_string_literal: true

require_relative 'test_helper'

class RiskManagerTest < Minitest::Test
  def setup
    # Sample returns data
    @returns = [0.01, -0.02, 0.015, -0.01, 0.005, 0.02, -0.015, 0.01, -0.005, 0.025]
    @prices = [100, 101, 99, 101.5, 100.5, 101, 103, 101.5, 102.5, 102, 104.5]
  end

  def test_historical_var
    var = SQA::RiskManager.var(@returns, confidence: 0.95, method: :historical)

    assert_instance_of Float, var
    assert var < 0, "VaR should be negative (represents loss)"
  end

  def test_parametric_var
    var = SQA::RiskManager.var(@returns, confidence: 0.95, method: :parametric)

    assert_instance_of Float, var
    assert var < 0
  end

  def test_monte_carlo_var
    var = SQA::RiskManager.var(@returns, confidence: 0.95, method: :monte_carlo, simulations: 1000)

    assert_instance_of Float, var
    assert var < 0
  end

  def test_cvar
    cvar = SQA::RiskManager.cvar(@returns, confidence: 0.95)

    assert_instance_of Float, cvar
    assert cvar < 0

    # CVaR should be more extreme than VaR
    var = SQA::RiskManager.var(@returns, confidence: 0.95)
    assert cvar <= var, "CVaR should be <= VaR"
  end

  def test_kelly_criterion
    position = SQA::RiskManager.kelly_criterion(
      win_rate: 0.60,
      avg_win: 0.10,
      avg_loss: 0.05,
      capital: 10_000,
      max_fraction: 0.25
    )

    assert_instance_of Float, position
    assert position > 0
    assert position <= 2500, "Should not exceed max_fraction * capital"
  end

  def test_kelly_criterion_with_bad_odds
    position = SQA::RiskManager.kelly_criterion(
      win_rate: 0.40,  # Poor win rate
      avg_win: 0.05,
      avg_loss: 0.10,
      capital: 10_000
    )

    assert position >= 0, "Kelly should not suggest negative position"
  end

  def test_fixed_fractional
    position = SQA::RiskManager.fixed_fractional(capital: 10_000, risk_fraction: 0.02)

    assert_equal 200.0, position
  end

  def test_percent_volatility
    shares = SQA::RiskManager.percent_volatility(
      capital: 10_000,
      returns: @returns,
      target_volatility: 0.15,
      current_price: 150.0
    )

    assert_instance_of Integer, shares
    assert shares >= 0
  end

  def test_atr_stop_loss_long
    stop = SQA::RiskManager.atr_stop_loss(
      current_price: 150.0,
      atr: 3.5,
      multiplier: 2.0,
      direction: :long
    )

    assert_equal 143.0, stop
    assert stop < 150.0, "Long stop should be below current price"
  end

  def test_atr_stop_loss_short
    stop = SQA::RiskManager.atr_stop_loss(
      current_price: 150.0,
      atr: 3.5,
      multiplier: 2.0,
      direction: :short
    )

    assert_equal 157.0, stop
    assert stop > 150.0, "Short stop should be above current price"
  end

  def test_max_drawdown
    result = SQA::RiskManager.max_drawdown(@prices)

    assert_instance_of Hash, result
    assert result.key?(:max_drawdown)
    assert result.key?(:peak_idx)
    assert result.key?(:trough_idx)

    assert result[:max_drawdown] <= 0, "Drawdown should be negative"
    assert result[:peak_idx] < result[:trough_idx], "Peak should come before trough"
  end

  def test_max_drawdown_with_uptrend
    uptrend = [100, 105, 110, 115, 120]
    result = SQA::RiskManager.max_drawdown(uptrend)

    assert_equal 0.0, result[:max_drawdown], "No drawdown in pure uptrend"
  end

  def test_sharpe_ratio
    sharpe = SQA::RiskManager.sharpe_ratio(@returns, risk_free_rate: 0.02)

    assert_instance_of Float, sharpe
  end

  def test_sortino_ratio
    sortino = SQA::RiskManager.sortino_ratio(@returns, target_return: 0.0)

    assert_instance_of Float, sortino
    # Sortino should be higher than Sharpe (only penalizes downside)
  end

  def test_sortino_with_no_downside
    positive_returns = [0.01, 0.02, 0.015, 0.01, 0.005]
    sortino = SQA::RiskManager.sortino_ratio(positive_returns)

    assert_equal Float::INFINITY, sortino
  end

  def test_calmar_ratio
    calmar = SQA::RiskManager.calmar_ratio(@returns)

    assert_instance_of Float, calmar
  end

  def test_monte_carlo_simulation
    result = SQA::RiskManager.monte_carlo_simulation(
      initial_capital: 10_000,
      returns: @returns,
      periods: 252,
      simulations: 100
    )

    assert_instance_of Hash, result
    assert result.key?(:mean)
    assert result.key?(:median)
    assert result.key?(:percentile_5)
    assert result.key?(:percentile_95)

    # Sanity checks
    assert result[:percentile_5] < result[:median]
    assert result[:median] < result[:percentile_95]
    assert result[:mean] > 0
  end

  def test_var_with_empty_returns
    var = SQA::RiskManager.var([], confidence: 0.95)
    assert_nil var
  end

  def test_cvar_with_empty_returns
    cvar = SQA::RiskManager.cvar([], confidence: 0.95)
    assert_nil var
  end
end
