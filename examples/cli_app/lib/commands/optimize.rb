#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base'

module Commands
  # Optimize command - Portfolio optimization and risk management
  class Optimize < Base
    METHODS = %w[sharpe variance risk_parity efficient_frontier].freeze

    private

    def default_options
      super.merge(
        tickers: ['AAPL', 'MSFT', 'GOOGL'],
        method: 'sharpe',
        risk_free_rate: 0.02,
        target_return: nil,
        risk_metrics: false
      )
    end

    def add_command_options(opts)
      opts.on('--tickers LIST', Array, 'Comma-separated list of tickers (default: AAPL,MSFT,GOOGL)') do |tickers|
        @options[:tickers] = tickers.map(&:upcase)
      end

      opts.on('-m', '--method METHOD', METHODS, 'Optimization method:', "  #{METHODS.join(', ')}") do |method|
        @options[:method] = method
      end

      opts.on('--risk-free-rate RATE', Float, 'Risk-free rate (default: 0.02)') do |rate|
        @options[:risk_free_rate] = rate
      end

      opts.on('--target-return RETURN', Float, 'Target return for optimization') do |target|
        @options[:target_return] = target
      end

      opts.on('--risk-metrics', 'Show risk metrics for each stock') do
        @options[:risk_metrics] = true
      end
    end

    def banner
      <<~BANNER
        Usage: sqa-cli optimize [options]

        Portfolio optimization and risk management across multiple stocks.

        Options:
      BANNER
    end

    public

    def execute
      print_header "Portfolio Optimization"

      puts "\nTickers: #{@options[:tickers].join(', ')}"
      puts "Method: #{@options[:method]}"
      puts

      # Load SQA on first use
      require 'sqa' unless defined?(SQA)

      # Load stocks
      print_section "Loading Stock Data"
      stocks = @options[:tickers].map do |ticker|
        puts "  Loading #{ticker}..." if @options[:verbose]
        SQA.init unless defined?(SQA::Stock)
        SQA::Stock.new(ticker: ticker)
      rescue => e
        puts "  Failed to load #{ticker}: #{e.message}"
        nil
      end.compact

      if stocks.empty?
        puts "Error: No stocks could be loaded"
        exit 1
      end

      puts "Loaded #{stocks.size} stocks"

      # Calculate returns matrix
      print_section "Calculating Returns"
      returns_matrix = stocks.map do |stock|
        prices = stock.df["adj_close_price"].to_a
        prices.each_cons(2).map { |a, b| (b - a) / a }
      end

      # Show risk metrics if requested
      if @options[:risk_metrics]
        show_risk_metrics(stocks, returns_matrix)
      end

      # Run optimization
      print_section "Running Optimization (#{@options[:method]})"

      result = case @options[:method]
              when 'sharpe'
                SQA::PortfolioOptimizer.maximum_sharpe(
                  returns_matrix,
                  risk_free_rate: @options[:risk_free_rate]
                )
              when 'variance'
                SQA::PortfolioOptimizer.minimum_variance(returns_matrix)
              when 'risk_parity'
                SQA::PortfolioOptimizer.risk_parity(returns_matrix)
              when 'efficient_frontier'
                run_efficient_frontier(returns_matrix)
                return
              else
                puts "Unknown optimization method: #{@options[:method]}"
                exit 1
              end

      # Display results
      puts "\nOptimal Portfolio Allocation:"
      puts "-" * 50
      @options[:tickers].each_with_index do |ticker, i|
        weight = result[:weights][i]
        puts "  #{ticker.ljust(10)} #{(weight * 100).round(2)}%"
      end

      puts "\nExpected Performance:"
      puts "  Return: #{(result[:return] * 100).round(2)}% (annualized)"
      puts "  Volatility: #{(result[:volatility] * 100).round(2)}%"
      puts "  Sharpe Ratio: #{result[:sharpe].round(2)}" if result[:sharpe]
    end

    private

    def show_risk_metrics(stocks, returns_matrix)
      print_section "Individual Stock Risk Metrics"

      stocks.each_with_index do |stock, i|
        returns = returns_matrix[i]
        prices = stock.df["adj_close_price"].to_a

        puts "\n#{@options[:tickers][i]}:"
        puts "  Annual Return: #{(returns.sum / returns.size * 252 * 100).round(2)}%"
        puts "  Volatility: #{(returns.std_dev * Math.sqrt(252) * 100).round(2)}%"
        puts "  Sharpe Ratio: #{SQA::RiskManager.sharpe_ratio(returns, risk_free_rate: @options[:risk_free_rate]).round(2)}"
        puts "  Max Drawdown: #{(SQA::RiskManager.max_drawdown(prices)[:max_drawdown] * 100).round(2)}%"
        puts "  VaR (95%): #{(SQA::RiskManager.var(returns, confidence: 0.95) * 100).round(2)}%"
      end
    end

    def run_efficient_frontier(returns_matrix)
      puts "\nCalculating efficient frontier..."

      frontier = SQA::PortfolioOptimizer.efficient_frontier(returns_matrix, points: 20)

      puts "\nEfficient Frontier (#{frontier.size} points):"
      puts "-" * 50
      puts "#{'Return'.ljust(12)} #{'Volatility'.ljust(12)} Sharpe"
      puts "-" * 50

      frontier.each do |point|
        puts "#{(point[:return] * 100).round(2).to_s.ljust(12)} #{(point[:volatility] * 100).round(2).to_s.ljust(12)} #{point[:sharpe].round(2)}"
      end

      # Find maximum Sharpe point
      max_sharpe_point = frontier.max_by { |p| p[:sharpe] }
      puts "\nMaximum Sharpe Ratio Point:"
      puts "  Return: #{(max_sharpe_point[:return] * 100).round(2)}%"
      puts "  Volatility: #{(max_sharpe_point[:volatility] * 100).round(2)}%"
      puts "  Sharpe: #{max_sharpe_point[:sharpe].round(2)}"
    end
  end
end
