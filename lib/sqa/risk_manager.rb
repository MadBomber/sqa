# lib/sqa/risk_manager.rb
# frozen_string_literal: true

module SQA
  ##
  # RiskManager - Comprehensive risk management and position sizing
  #
  # Provides methods for:
  # - Value at Risk (VaR): Historical, Parametric, Monte Carlo
  # - Conditional VaR (CVaR / Expected Shortfall)
  # - Position sizing: Kelly Criterion, Fixed Fractional, Percent Volatility
  # - Risk metrics: Sharpe, Sortino, Calmar, Maximum Drawdown
  # - Stop loss calculations
  #
  # @example Basic VaR calculation
  #   returns = stock.df["adj_close_price"].to_a.each_cons(2).map { |a, b| (b - a) / a }
  #   var_95 = SQA::RiskManager.var(returns, confidence: 0.95)
  #   puts "95% VaR: #{var_95}%"
  #
  # @example Position sizing with Kelly Criterion
  #   position = SQA::RiskManager.kelly_criterion(
  #     win_rate: 0.55,
  #     avg_win: 0.15,
  #     avg_loss: 0.10,
  #     capital: 10_000
  #   )
  #   puts "Optimal position size: $#{position}"
  #
  class RiskManager
    class << self
      ##
      # Calculate Value at Risk (VaR) using historical method
      #
      # VaR represents the maximum expected loss over a given time period
      # at a specified confidence level.
      #
      # @param returns [Array<Float>] Array of period returns (e.g., daily returns)
      # @param confidence [Float] Confidence level (default: 0.95 for 95%)
      # @param method [Symbol] Method to use (:historical, :parametric, :monte_carlo)
      # @param simulations [Integer] Number of Monte Carlo simulations (if method is :monte_carlo)
      # @return [Float] Value at Risk as a percentage
      #
      # @example
      #   returns = [0.01, -0.02, 0.015, -0.01, 0.005]
      #   var = SQA::RiskManager.var(returns, confidence: 0.95)
      #   # => -0.02 (2% maximum expected loss at 95% confidence)
      #
      def var(returns, confidence: 0.95, method: :historical, simulations: 10_000)
        return nil if returns.empty?

        case method
        when :historical
          historical_var(returns, confidence)
        when :parametric
          parametric_var(returns, confidence)
        when :monte_carlo
          monte_carlo_var(returns, confidence, simulations)
        else
          raise ArgumentError, "Unknown VaR method: #{method}"
        end
      end

      ##
      # Calculate Conditional Value at Risk (CVaR / Expected Shortfall)
      #
      # CVaR is the expected loss given that the loss exceeds the VaR threshold.
      # It provides a more conservative risk measure than VaR.
      #
      # @param returns [Array<Float>] Array of period returns
      # @param confidence [Float] Confidence level (default: 0.95)
      # @return [Float] CVaR as a percentage
      #
      # @example
      #   cvar = SQA::RiskManager.cvar(returns, confidence: 0.95)
      #   # => -0.025 (2.5% expected loss in worst 5% of cases)
      #
      def cvar(returns, confidence: 0.95)
        return nil if returns.empty?

        var_threshold = var(returns, confidence: confidence, method: :historical)
        tail_losses = returns.select { |r| r <= var_threshold }

        return nil if tail_losses.empty?
        tail_losses.sum / tail_losses.size.to_f
      end

      ##
      # Calculate position size using Kelly Criterion
      #
      # Kelly Criterion calculates the optimal fraction of capital to risk
      # based on win rate and win/loss ratio.
      #
      # Formula: f = (p * b - q) / b
      # where:
      #   f = fraction of capital to bet
      #   p = probability of winning
      #   q = probability of losing (1 - p)
      #   b = win/loss ratio (avg_win / avg_loss)
      #
      # @param win_rate [Float] Win rate (0.0 to 1.0)
      # @param avg_win [Float] Average win size (as percentage)
      # @param avg_loss [Float] Average loss size (as percentage)
      # @param capital [Float] Total capital available
      # @param max_fraction [Float] Maximum fraction to risk (default: 0.25 for 25%)
      # @return [Float] Dollar amount to risk
      #
      # @example
      #   position = SQA::RiskManager.kelly_criterion(
      #     win_rate: 0.60,
      #     avg_win: 0.10,
      #     avg_loss: 0.05,
      #     capital: 10_000,
      #     max_fraction: 0.25
      #   )
      #
      def kelly_criterion(win_rate:, avg_win:, avg_loss:, capital:, max_fraction: 0.25)
        return 0.0 if avg_loss.zero? || win_rate >= 1.0 || win_rate <= 0.0

        lose_rate = 1.0 - win_rate
        win_loss_ratio = avg_win / avg_loss

        # Kelly formula
        kelly_fraction = (win_rate * win_loss_ratio - lose_rate) / win_loss_ratio

        # Cap at max_fraction (Kelly can be aggressive)
        kelly_fraction = [kelly_fraction, max_fraction].min
        kelly_fraction = [kelly_fraction, 0.0].max  # No negative positions

        capital * kelly_fraction
      end

      ##
      # Calculate position size using Fixed Fractional method
      #
      # Risk a fixed percentage of capital on each trade.
      # Simple and conservative approach.
      #
      # @param capital [Float] Total capital
      # @param risk_fraction [Float] Fraction to risk (e.g., 0.02 for 2%)
      # @return [Float] Dollar amount to risk
      #
      # @example
      #   position = SQA::RiskManager.fixed_fractional(capital: 10_000, risk_fraction: 0.02)
      #   # => 200.0 (risk $200 per trade)
      #
      def fixed_fractional(capital:, risk_fraction: 0.02)
        capital * risk_fraction
      end

      ##
      # Calculate position size using Percent Volatility method
      #
      # Adjust position size based on recent volatility.
      # Higher volatility = smaller position size.
      #
      # @param capital [Float] Total capital
      # @param returns [Array<Float>] Recent returns
      # @param target_volatility [Float] Target portfolio volatility (annualized)
      # @param current_price [Float] Current asset price
      # @return [Integer] Number of shares to buy
      #
      # @example
      #   shares = SQA::RiskManager.percent_volatility(
      #     capital: 10_000,
      #     returns: recent_returns,
      #     target_volatility: 0.15,
      #     current_price: 150.0
      #   )
      #
      def percent_volatility(capital:, returns:, target_volatility: 0.15, current_price:)
        return 0 if returns.empty? || current_price.zero?

        # Calculate recent volatility (annualized)
        std_dev = standard_deviation(returns)
        annualized_volatility = std_dev * Math.sqrt(252)  # Assume 252 trading days

        return 0 if annualized_volatility.zero?

        # Calculate position size
        position_value = capital * (target_volatility / annualized_volatility)
        shares = (position_value / current_price).floor

        [shares, 0].max  # No negative shares
      end

      ##
      # Calculate stop loss price based on ATR (Average True Range)
      #
      # @param current_price [Float] Current asset price
      # @param atr [Float] Average True Range
      # @param multiplier [Float] ATR multiplier (default: 2.0)
      # @param direction [Symbol] :long or :short
      # @return [Float] Stop loss price
      #
      # @example
      #   stop = SQA::RiskManager.atr_stop_loss(
      #     current_price: 150.0,
      #     atr: 3.5,
      #     multiplier: 2.0,
      #     direction: :long
      #   )
      #   # => 143.0 (stop at current - 2*ATR)
      #
      def atr_stop_loss(current_price:, atr:, multiplier: 2.0, direction: :long)
        if direction == :long
          current_price - (atr * multiplier)
        else
          current_price + (atr * multiplier)
        end
      end

      ##
      # Calculate maximum drawdown from price series
      #
      # Drawdown is the peak-to-trough decline in portfolio value.
      #
      # @param prices [Array<Float>] Array of prices or portfolio values
      # @return [Hash] { max_drawdown: Float, peak_idx: Integer, trough_idx: Integer }
      #
      # @example
      #   dd = SQA::RiskManager.max_drawdown([100, 110, 105, 95, 100])
      #   # => { max_drawdown: -0.136, peak_idx: 1, trough_idx: 3 }
      #
      def max_drawdown(prices)
        return { max_drawdown: 0.0, peak_idx: 0, trough_idx: 0 } if prices.size < 2

        max_dd = 0.0
        peak_idx = 0
        trough_idx = 0
        running_peak = prices.first
        running_peak_idx = 0

        prices.each_with_index do |price, idx|
          if price > running_peak
            running_peak = price
            running_peak_idx = idx
          end

          drawdown = (price - running_peak) / running_peak
          if drawdown < max_dd
            max_dd = drawdown
            peak_idx = running_peak_idx
            trough_idx = idx
          end
        end

        {
          max_drawdown: max_dd,
          peak_idx: peak_idx,
          trough_idx: trough_idx,
          peak_value: prices[peak_idx],
          trough_value: prices[trough_idx]
        }
      end

      ##
      # Calculate Sharpe Ratio
      #
      # Measures risk-adjusted return (excess return per unit of risk).
      #
      # @param returns [Array<Float>] Array of period returns
      # @param risk_free_rate [Float] Risk-free rate (annualized, default: 0.02)
      # @param periods_per_year [Integer] Number of periods per year (default: 252 for daily)
      # @return [Float] Sharpe ratio
      #
      # @example
      #   sharpe = SQA::RiskManager.sharpe_ratio(returns, risk_free_rate: 0.02)
      #
      def sharpe_ratio(returns, risk_free_rate: 0.02, periods_per_year: 252)
        return 0.0 if returns.empty?

        excess_returns = returns.map { |r| r - (risk_free_rate / periods_per_year) }
        mean_excess = excess_returns.sum / excess_returns.size.to_f
        std_excess = standard_deviation(excess_returns)

        return 0.0 if std_excess.zero?

        (mean_excess / std_excess) * Math.sqrt(periods_per_year)
      end

      ##
      # Calculate Sortino Ratio
      #
      # Like Sharpe ratio but only penalizes downside volatility.
      #
      # @param returns [Array<Float>] Array of period returns
      # @param target_return [Float] Target return (default: 0.0)
      # @param periods_per_year [Integer] Number of periods per year (default: 252)
      # @return [Float] Sortino ratio
      #
      # @example
      #   sortino = SQA::RiskManager.sortino_ratio(returns)
      #
      def sortino_ratio(returns, target_return: 0.0, periods_per_year: 252)
        return 0.0 if returns.empty?

        excess_returns = returns.map { |r| r - target_return }
        mean_excess = excess_returns.sum / excess_returns.size.to_f

        # Downside deviation (only negative returns)
        downside_returns = excess_returns.select { |r| r < 0 }
        return Float::INFINITY if downside_returns.empty?

        downside_deviation = Math.sqrt(
          downside_returns.map { |r| r**2 }.sum / downside_returns.size.to_f
        )

        return 0.0 if downside_deviation.zero?

        (mean_excess / downside_deviation) * Math.sqrt(periods_per_year)
      end

      ##
      # Calculate Calmar Ratio
      #
      # Ratio of annualized return to maximum drawdown.
      #
      # @param returns [Array<Float>] Array of period returns
      # @param periods_per_year [Integer] Number of periods per year (default: 252)
      # @return [Float] Calmar ratio
      #
      # @example
      #   calmar = SQA::RiskManager.calmar_ratio(returns)
      #
      def calmar_ratio(returns, periods_per_year: 252)
        return 0.0 if returns.empty?

        # Annualized return
        total_return = returns.inject(1.0) { |product, r| product * (1 + r) }
        periods = returns.size
        annualized_return = (total_return ** (periods_per_year.to_f / periods)) - 1.0

        # Convert returns to prices for drawdown calculation
        prices = returns.inject([100.0]) { |acc, r| acc << acc.last * (1 + r) }
        max_dd = max_drawdown(prices)[:max_drawdown].abs

        return 0.0 if max_dd.zero?

        annualized_return / max_dd
      end

      ##
      # Monte Carlo simulation for portfolio value
      #
      # @param initial_capital [Float] Starting capital
      # @param returns [Array<Float>] Historical returns to sample from
      # @param periods [Integer] Number of periods to simulate
      # @param simulations [Integer] Number of simulation paths
      # @return [Hash] Simulation results with percentiles
      #
      # @example
      #   results = SQA::RiskManager.monte_carlo_simulation(
      #     initial_capital: 10_000,
      #     returns: historical_returns,
      #     periods: 252,
      #     simulations: 1000
      #   )
      #   puts "95th percentile: $#{results[:percentile_95]}"
      #
      def monte_carlo_simulation(initial_capital:, returns:, periods:, simulations: 1000)
        return nil if returns.empty?

        final_values = simulations.times.map do
          value = initial_capital
          periods.times do
            random_return = returns.sample
            value *= (1 + random_return)
          end
          value
        end

        final_values.sort!

        {
          mean: final_values.sum / final_values.size.to_f,
          median: final_values[final_values.size / 2],
          percentile_5: final_values[(final_values.size * 0.05).floor],
          percentile_25: final_values[(final_values.size * 0.25).floor],
          percentile_75: final_values[(final_values.size * 0.75).floor],
          percentile_95: final_values[(final_values.size * 0.95).floor],
          min: final_values.first,
          max: final_values.last,
          all_values: final_values
        }
      end

      private

      ##
      # Historical VaR calculation
      def historical_var(returns, confidence)
        sorted = returns.sort
        index = ((1 - confidence) * sorted.size).floor
        sorted[index]
      end

      ##
      # Parametric VaR (assumes normal distribution)
      def parametric_var(returns, confidence)
        mean = returns.sum / returns.size.to_f
        std_dev = standard_deviation(returns)

        # Z-score for confidence level
        z_score = {
          0.90 => -1.28,
          0.95 => -1.645,
          0.99 => -2.33
        }[confidence] || -1.645

        mean + (z_score * std_dev)
      end

      ##
      # Monte Carlo VaR
      def monte_carlo_var(returns, confidence, simulations)
        mean = returns.sum / returns.size.to_f
        std_dev = standard_deviation(returns)

        # Generate random returns
        simulated = simulations.times.map do
          # Box-Muller transform for normal distribution
          u1 = rand
          u2 = rand
          z = Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math::PI * u2)
          mean + (std_dev * z)
        end

        historical_var(simulated, confidence)
      end

      ##
      # Calculate standard deviation
      def standard_deviation(values)
        return 0.0 if values.empty?

        mean = values.sum / values.size.to_f
        variance = values.map { |v| (v - mean)**2 }.sum / values.size.to_f
        Math.sqrt(variance)
      end
    end
  end
end
