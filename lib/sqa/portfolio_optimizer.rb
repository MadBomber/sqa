# lib/sqa/portfolio_optimizer.rb
# frozen_string_literal: true

module SQA
  ##
  # PortfolioOptimizer - Multi-objective portfolio optimization
  #
  # Provides methods for:
  # - Mean-Variance Optimization (Markowitz)
  # - Multi-objective optimization (return vs risk vs drawdown)
  # - Efficient Frontier calculation
  # - Risk Parity allocation
  # - Minimum Variance portfolio
  # - Maximum Sharpe portfolio
  #
  # @example Find optimal portfolio weights
  #   returns_matrix = [
  #     [0.01, -0.02, 0.015],  # Stock 1 returns
  #     [0.02, 0.01, -0.01],   # Stock 2 returns
  #     [-0.01, 0.03, 0.02]    # Stock 3 returns
  #   ]
  #   weights = SQA::PortfolioOptimizer.maximum_sharpe(returns_matrix)
  #   # => [0.4, 0.3, 0.3]
  #
  class PortfolioOptimizer
    class << self
      ##
      # Calculate portfolio returns given weights
      #
      # @param returns_matrix [Array<Array<Float>>] Returns for each asset (rows = assets, cols = periods)
      # @param weights [Array<Float>] Portfolio weights (must sum to 1.0)
      # @return [Array<Float>] Portfolio returns over time
      #
      def portfolio_returns(returns_matrix, weights)
        num_periods = returns_matrix.first.size

        num_periods.times.map do |period_idx|
          returns_matrix.each_with_index.sum do |asset_returns, asset_idx|
            asset_returns[period_idx] * weights[asset_idx]
          end
        end
      end

      ##
      # Calculate portfolio variance
      #
      # @param returns_matrix [Array<Array<Float>>] Returns for each asset
      # @param weights [Array<Float>] Portfolio weights
      # @return [Float] Portfolio variance
      #
      def portfolio_variance(returns_matrix, weights)
        covariance_matrix = calculate_covariance_matrix(returns_matrix)

        # Portfolio variance = w^T * Σ * w
        variance = 0.0
        weights.each_with_index do |wi, i|
          weights.each_with_index do |wj, j|
            variance += wi * wj * covariance_matrix[i][j]
          end
        end

        variance
      end

      ##
      # Find Maximum Sharpe Ratio portfolio
      #
      # Uses numerical optimization to find weights that maximize Sharpe ratio.
      #
      # @param returns_matrix [Array<Array<Float>>] Returns for each asset
      # @param risk_free_rate [Float] Risk-free rate (default: 0.02)
      # @param constraints [Hash] Optimization constraints
      # @return [Hash] { weights: Array, sharpe: Float, return: Float, volatility: Float }
      #
      def maximum_sharpe(returns_matrix, risk_free_rate: 0.02, constraints: {})
        num_assets = returns_matrix.size

        # Grid search optimization (simple but effective)
        best_sharpe = -Float::INFINITY
        best_weights = nil

        # Try random portfolios
        10_000.times do
          weights = random_weights(num_assets, constraints)

          port_returns = portfolio_returns(returns_matrix, weights)
          sharpe = SQA::RiskManager.sharpe_ratio(port_returns, risk_free_rate: risk_free_rate)

          if sharpe > best_sharpe
            best_sharpe = sharpe
            best_weights = weights
          end
        end

        port_returns = portfolio_returns(returns_matrix, best_weights)
        mean_return = port_returns.sum / port_returns.size.to_f
        volatility = Math.sqrt(portfolio_variance(returns_matrix, best_weights))

        {
          weights: best_weights,
          sharpe: best_sharpe,
          return: mean_return * 252,  # Annualized
          volatility: volatility * Math.sqrt(252)  # Annualized
        }
      end

      ##
      # Find Minimum Variance portfolio
      #
      # @param returns_matrix [Array<Array<Float>>] Returns for each asset
      # @param constraints [Hash] Optimization constraints
      # @return [Hash] { weights: Array, variance: Float, volatility: Float }
      #
      def minimum_variance(returns_matrix, constraints: {})
        num_assets = returns_matrix.size

        best_variance = Float::INFINITY
        best_weights = nil

        # Grid search
        10_000.times do
          weights = random_weights(num_assets, constraints)
          variance = portfolio_variance(returns_matrix, weights)

          if variance < best_variance
            best_variance = variance
            best_weights = weights
          end
        end

        {
          weights: best_weights,
          variance: best_variance,
          volatility: Math.sqrt(best_variance) * Math.sqrt(252)  # Annualized
        }
      end

      ##
      # Calculate Risk Parity portfolio
      #
      # Allocate weights so each asset contributes equally to portfolio risk.
      #
      # @param returns_matrix [Array<Array<Float>>] Returns for each asset
      # @return [Hash] { weights: Array, volatility: Float }
      #
      def risk_parity(returns_matrix)
        # Calculate individual volatilities
        volatilities = returns_matrix.map do |asset_returns|
          mean = asset_returns.sum / asset_returns.size.to_f
          variance = asset_returns.map { |r| (r - mean)**2 }.sum / asset_returns.size.to_f
          Math.sqrt(variance)
        end

        # Inverse volatility weighting (approximation of risk parity)
        inv_vols = volatilities.map { |v| 1.0 / v }
        sum_inv_vols = inv_vols.sum

        weights = inv_vols.map { |iv| iv / sum_inv_vols }

        {
          weights: weights,
          volatility: Math.sqrt(portfolio_variance(returns_matrix, weights)) * Math.sqrt(252)
        }
      end

      ##
      # Calculate Efficient Frontier
      #
      # Generate portfolios along the efficient frontier.
      #
      # @param returns_matrix [Array<Array<Float>>] Returns for each asset
      # @param num_portfolios [Integer] Number of portfolios to generate
      # @return [Array<Hash>] Array of portfolio hashes
      #
      def efficient_frontier(returns_matrix, num_portfolios: 50)
        portfolios = []

        num_portfolios.times do
          weights = random_weights(returns_matrix.size, {})

          port_returns = portfolio_returns(returns_matrix, weights)
          mean_return = port_returns.sum / port_returns.size.to_f
          variance = portfolio_variance(returns_matrix, weights)
          volatility = Math.sqrt(variance)

          portfolios << {
            weights: weights,
            return: mean_return * 252,
            volatility: volatility * Math.sqrt(252),
            sharpe: SQA::RiskManager.sharpe_ratio(port_returns)
          }
        end

        # Sort by volatility
        portfolios.sort_by { |p| p[:volatility] }
      end

      ##
      # Multi-objective optimization
      #
      # Optimize portfolio for multiple objectives simultaneously.
      #
      # @param returns_matrix [Array<Array<Float>>] Returns for each asset
      # @param objectives [Hash] Objectives with weights
      # @return [Hash] Optimal portfolio
      #
      # @example
      #   result = SQA::PortfolioOptimizer.multi_objective(
      #     returns_matrix,
      #     objectives: {
      #       maximize_return: 0.4,
      #       minimize_volatility: 0.3,
      #       minimize_drawdown: 0.3
      #     }
      #   )
      #
      def multi_objective(returns_matrix, objectives: {})
        num_assets = returns_matrix.size

        best_score = -Float::INFINITY
        best_portfolio = nil

        # Default objectives
        objectives = {
          maximize_return: 0.33,
          minimize_volatility: 0.33,
          minimize_drawdown: 0.34
        } if objectives.empty?

        # Normalize objective weights
        total_weight = objectives.values.sum
        objectives = objectives.transform_values { |v| v / total_weight }

        # Grid search
        10_000.times do
          weights = random_weights(num_assets, {})

          port_returns = portfolio_returns(returns_matrix, weights)
          mean_return = port_returns.sum / port_returns.size.to_f
          variance = portfolio_variance(returns_matrix, weights)
          volatility = Math.sqrt(variance)

          # Convert to prices for drawdown
          prices = port_returns.inject([100.0]) { |acc, r| acc << acc.last * (1 + r) }
          max_dd = SQA::RiskManager.max_drawdown(prices)[:max_drawdown].abs

          # Calculate composite score
          score = 0.0

          # Normalize and combine objectives
          if objectives[:maximize_return]
            score += (mean_return * 252) * objectives[:maximize_return] * 10  # Scale up
          end

          if objectives[:minimize_volatility]
            score -= (volatility * Math.sqrt(252)) * objectives[:minimize_volatility] * 10
          end

          if objectives[:minimize_drawdown]
            score -= max_dd * objectives[:minimize_drawdown] * 10
          end

          if score > best_score
            best_score = score
            best_portfolio = {
              weights: weights,
              return: mean_return * 252,
              volatility: volatility * Math.sqrt(252),
              max_drawdown: max_dd,
              sharpe: SQA::RiskManager.sharpe_ratio(port_returns),
              composite_score: score
            }
          end
        end

        best_portfolio
      end

      ##
      # Equal weight portfolio (1/N rule)
      #
      # @param num_assets [Integer] Number of assets
      # @return [Array<Float>] Equal weights
      #
      def equal_weight(num_assets)
        weight = 1.0 / num_assets
        Array.new(num_assets, weight)
      end

      ##
      # Rebalance portfolio to target weights
      #
      # @param current_values [Hash] Current holdings { ticker => value }
      # @param target_weights [Hash] Target weights { ticker => weight }
      # @param total_value [Float] Total portfolio value
      # @return [Hash] Rebalancing trades { ticker => { action: :buy/:sell, shares: N, value: $ } }
      #
      def rebalance(current_values:, target_weights:, total_value:, prices:)
        trades = {}

        target_weights.each do |ticker, target_weight|
          current_value = current_values[ticker] || 0.0
          target_value = total_value * target_weight
          difference = target_value - current_value

          next if difference.abs < 1.0  # Skip tiny adjustments

          price = prices[ticker]
          next if price.nil? || price.zero?

          shares = (difference / price).round

          trades[ticker] = {
            action: shares > 0 ? :buy : :sell,
            shares: shares.abs,
            value: shares * price,
            current_weight: current_value / total_value,
            target_weight: target_weight
          }
        end

        trades
      end

      private

      ##
      # Calculate covariance matrix
      def calculate_covariance_matrix(returns_matrix)
        num_assets = returns_matrix.size
        num_periods = returns_matrix.first.size

        # Calculate means
        means = returns_matrix.map do |returns|
          returns.sum / returns.size.to_f
        end

        # Calculate covariance
        covariance = Array.new(num_assets) { Array.new(num_assets, 0.0) }

        num_assets.times do |i|
          num_assets.times do |j|
            cov = 0.0
            num_periods.times do |t|
              cov += (returns_matrix[i][t] - means[i]) * (returns_matrix[j][t] - means[j])
            end
            covariance[i][j] = cov / (num_periods - 1).to_f
          end
        end

        covariance
      end

      ##
      # Generate random portfolio weights
      def random_weights(num_assets, constraints)
        # Generate random weights that sum to 1.0
        weights = num_assets.times.map { rand }
        sum = weights.sum
        weights = weights.map { |w| w / sum }

        # Apply constraints
        min_weight = constraints[:min_weight] || 0.0
        max_weight = constraints[:max_weight] || 1.0

        # Adjust if constraints violated
        weights = weights.map do |w|
          [[w, min_weight].max, max_weight].min
        end

        # Renormalize
        sum = weights.sum
        weights.map { |w| w / sum }
      end
    end
  end
end
