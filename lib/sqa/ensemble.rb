# lib/sqa/ensemble.rb
# frozen_string_literal: true

module SQA
  ##
  # Ensemble - Combine multiple trading strategies
  #
  # Provides methods for:
  # - Majority voting
  # - Weighted voting based on past performance
  # - Meta-learning (strategy selection)
  # - Strategy rotation based on market conditions
  # - Confidence-based aggregation
  #
  # @example Simple majority voting
  #   ensemble = SQA::Ensemble.new(
  #     strategies: [SQA::Strategy::RSI, SQA::Strategy::MACD, SQA::Strategy::Bollinger]
  #   )
  #   signal = ensemble.vote(vector)
  #   # => :buy (if 2 out of 3 say :buy)
  #
  class Ensemble
    attr_accessor :strategies, :weights, :performance_history

    ##
    # Initialize ensemble
    #
    # @param strategies [Array<Class>] Array of strategy classes
    # @param voting_method [Symbol] :majority, :weighted, :unanimous, :confidence
    # @param weights [Array<Float>] Optional weights for weighted voting
    #
    def initialize(strategies:, voting_method: :majority, weights: nil)
      @strategies = strategies
      @voting_method = voting_method
      @weights = weights || Array.new(strategies.size, 1.0 / strategies.size)
      @performance_history = Hash.new { |h, k| h[k] = [] }
      @confidence_scores = Hash.new(0.5)
    end

    ##
    # Generate ensemble signal
    #
    # @param vector [OpenStruct] Market data vector
    # @return [Symbol] :buy, :sell, or :hold
    #
    def signal(vector)
      case @voting_method
      when :majority
        majority_vote(vector)
      when :weighted
        weighted_vote(vector)
      when :unanimous
        unanimous_vote(vector)
      when :confidence
        confidence_vote(vector)
      else
        majority_vote(vector)
      end
    end

    ##
    # Majority voting
    #
    # @param vector [OpenStruct] Market data
    # @return [Symbol] Signal with most votes
    #
    def majority_vote(vector)
      votes = collect_votes(vector)

      # Count votes
      vote_counts = { buy: 0, sell: 0, hold: 0 }
      votes.each { |v| vote_counts[v] += 1 }

      # Return signal with most votes
      vote_counts.max_by { |_signal, count| count }.first
    end

    ##
    # Weighted voting based on strategy performance
    #
    # @param vector [OpenStruct] Market data
    # @return [Symbol] Weighted signal
    #
    def weighted_vote(vector)
      votes = collect_votes(vector)

      # Weighted scores
      scores = { buy: 0.0, sell: 0.0, hold: 0.0 }

      votes.each_with_index do |vote, idx|
        scores[vote] += @weights[idx]
      end

      # Return signal with highest weighted score
      scores.max_by { |_signal, score| score }.first
    end

    ##
    # Unanimous voting (all strategies must agree)
    #
    # @param vector [OpenStruct] Market data
    # @return [Symbol] :buy/:sell only if unanimous, otherwise :hold
    #
    def unanimous_vote(vector)
      votes = collect_votes(vector)

      # All must agree
      if votes.all? { |v| v == :buy }
        :buy
      elsif votes.all? { |v| v == :sell }
        :sell
      else
        :hold
      end
    end

    ##
    # Confidence-based voting
    #
    # Weight votes by strategy confidence scores.
    #
    # @param vector [OpenStruct] Market data
    # @return [Symbol] Signal weighted by confidence
    #
    def confidence_vote(vector)
      votes = collect_votes(vector)

      scores = { buy: 0.0, sell: 0.0, hold: 0.0 }

      votes.each_with_index do |vote, idx|
        strategy_class = @strategies[idx]
        confidence = @confidence_scores[strategy_class] || 0.5
        scores[vote] += confidence
      end

      scores.max_by { |_signal, score| score }.first
    end

    ##
    # Update strategy weights based on performance
    #
    # Adjust weights to favor better-performing strategies.
    #
    # @param strategy_index [Integer] Index of strategy
    # @param performance [Float] Performance metric (e.g., return)
    #
    def update_weight(strategy_index, performance)
      @performance_history[@strategies[strategy_index]] << performance

      # Recalculate weights based on recent performance
      recalculate_weights
    end

    ##
    # Update confidence score for strategy
    #
    # @param strategy_class [Class] Strategy class
    # @param correct [Boolean] Was the prediction correct?
    #
    def update_confidence(strategy_class, correct)
      current = @confidence_scores[strategy_class]

      # Exponential moving average of correctness
      alpha = 0.1
      @confidence_scores[strategy_class] = if correct
                                             current + alpha * (1.0 - current)
                                           else
                                             current - alpha * current
                                           end
    end

    ##
    # Select best strategy for current market conditions
    #
    # Meta-learning approach: choose the strategy most likely to succeed.
    #
    # @param market_regime [Symbol] Current market regime (:bull, :bear, :sideways)
    # @param volatility [Symbol] Volatility regime (:low, :medium, :high)
    # @return [Class] Best strategy class for conditions
    #
    def select_strategy(market_regime:, volatility: :medium)
      # Strategy performance by market condition
      # This could be learned from historical data
      strategy_preferences = {
        bull: {
          low: SQA::Strategy::EMA,
          medium: SQA::Strategy::MACD,
          high: SQA::Strategy::Bollinger
        },
        bear: {
          low: SQA::Strategy::RSI,
          medium: SQA::Strategy::RSI,
          high: SQA::Strategy::Bollinger
        },
        sideways: {
          low: SQA::Strategy::MR,
          medium: SQA::Strategy::MR,
          high: SQA::Strategy::Bollinger
        }
      }

      # Return preferred strategy or fall back to best performer
      strategy_preferences.dig(market_regime, volatility) ||
        best_performing_strategy
    end

    ##
    # Rotate strategies based on market conditions
    #
    # @param stock [SQA::Stock] Stock object
    # @return [Class] Strategy to use
    #
    def rotate(stock)
      regime_data = SQA::MarketRegime.detect(stock)

      select_strategy(
        market_regime: regime_data[:type],
        volatility: regime_data[:volatility]
      )
    end

    ##
    # Get ensemble statistics
    #
    # @return [Hash] Performance statistics
    #
    def statistics
      {
        num_strategies: @strategies.size,
        weights: @weights,
        confidence_scores: @confidence_scores,
        best_strategy: best_performing_strategy,
        worst_strategy: worst_performing_strategy,
        performance_history: @performance_history
      }
    end

    ##
    # Backtest ensemble vs individual strategies
    #
    # @param stock [SQA::Stock] Stock to backtest
    # @param initial_capital [Float] Starting capital
    # @return [Hash] Comparison results
    #
    def backtest_comparison(stock, initial_capital: 10_000)
      results = {}

      # Backtest ensemble
      ensemble_backtest = SQA::Backtest.new(
        stock: stock,
        strategy: self,
        initial_capital: initial_capital
      )
      results[:ensemble] = ensemble_backtest.run

      # Backtest each individual strategy
      @strategies.each do |strategy_class|
        individual_backtest = SQA::Backtest.new(
          stock: stock,
          strategy: strategy_class,
          initial_capital: initial_capital
        )
        results[strategy_class.name] = individual_backtest.run
      end

      results
    end

    ##
    # Make ensemble compatible with Backtest (acts like a strategy)
    #
    # @param vector [OpenStruct] Market data
    # @return [Symbol] Trading signal
    #
    def self.trade(vector)
      # This won't work for class method, use instance instead
      raise NotImplementedError, "Use ensemble instance, not class"
    end

    ##
    # Instance method for compatibility
    #
    def trade(vector)
      signal(vector)
    end

    private

    ##
    # Collect votes from all strategies
    #
    def collect_votes(vector)
      @strategies.map do |strategy_class|
        begin
          strategy_class.trade(vector)
        rescue StandardError => e
          # If strategy fails, default to :hold
          :hold
        end
      end
    end

    ##
    # Recalculate weights based on performance history
    #
    def recalculate_weights
      # Use recent performance (last 10 trades)
      recent_performance = @strategies.map do |strategy_class|
        history = @performance_history[strategy_class]
        recent = history.last(10)
        recent.empty? ? 0.0 : recent.sum / recent.size.to_f
      end

      # Convert to positive values (shift if negative)
      min_perf = recent_performance.min
      if min_perf < 0
        recent_performance = recent_performance.map { |p| p - min_perf + 0.01 }
      end

      # Normalize to sum to 1.0
      total = recent_performance.sum
      @weights = if total.zero?
                   Array.new(@strategies.size, 1.0 / @strategies.size)
                 else
                   recent_performance.map { |p| p / total }
                 end
    end

    ##
    # Find best performing strategy
    #
    def best_performing_strategy
      return @strategies.first if @performance_history.empty?

      avg_performance = @strategies.map do |strategy_class|
        history = @performance_history[strategy_class]
        avg = history.empty? ? 0.0 : history.sum / history.size.to_f
        [strategy_class, avg]
      end

      avg_performance.max_by { |_strategy, avg| avg }&.first || @strategies.first
    end

    ##
    # Find worst performing strategy
    #
    def worst_performing_strategy
      return @strategies.first if @performance_history.empty?

      avg_performance = @strategies.map do |strategy_class|
        history = @performance_history[strategy_class]
        avg = history.empty? ? 0.0 : history.sum / history.size.to_f
        [strategy_class, avg]
      end

      avg_performance.min_by { |_strategy, avg| avg }&.first || @strategies.first
    end
  end
end
