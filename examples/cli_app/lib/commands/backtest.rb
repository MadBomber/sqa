#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base'

module Commands
  # Backtest command - Run strategy backtests on historical data
  class Backtest < Base
    STRATEGIES = %w[RSI SMA EMA MACD BollingerBands Stochastic VolumeBreakout KBS Consensus Random].freeze

    private

    def default_options
      super.merge(
        strategy: 'RSI',
        capital: 10_000.0,
        commission: 1.0,
        compare: false
      )
    end

    def add_command_options(opts)
      opts.on('-s', '--strategy NAME', STRATEGIES, 'Strategy to backtest:', "  #{STRATEGIES.join(', ')}") do |strategy|
        @options[:strategy] = strategy
      end

      opts.on('-c', '--capital AMOUNT', Float, 'Initial capital (default: 10000)') do |capital|
        @options[:capital] = capital
      end

      opts.on('--commission AMOUNT', Float, 'Commission per trade (default: 1.0)') do |commission|
        @options[:commission] = commission
      end

      opts.on('--compare', 'Compare against all strategies') do
        @options[:compare] = true
      end
    end

    def banner
      <<~BANNER
        Usage: sqa-cli backtest [options]

        Run strategy backtests on historical stock data.

        Options:
      BANNER
    end

    public

    def execute
      stock = load_stock
      print_header "Backtesting #{@options[:strategy]} on #{@options[:ticker]}"

      if @options[:compare]
        compare_strategies(stock)
      else
        run_single_backtest(stock)
      end
    end

    private

    def run_single_backtest(stock)
      strategy_class = resolve_strategy(@options[:strategy])

      backtest = SQA::Backtest.new(
        stock: stock,
        strategy: strategy_class,
        initial_capital: @options[:capital],
        commission: @options[:commission]
      )

      results = backtest.run
      print_results(results)
    end

    def compare_strategies(stock)
      print_section "Comparing All Strategies"

      results_data = STRATEGIES.map do |strategy_name|
        strategy_class = resolve_strategy(strategy_name)

        backtest = SQA::Backtest.new(
          stock: stock,
          strategy: strategy_class,
          initial_capital: @options[:capital],
          commission: @options[:commission]
        )

        results = backtest.run

        {
          strategy: strategy_name,
          return: results.total_return,
          sharpe: results.sharpe_ratio,
          drawdown: results.max_drawdown,
          win_rate: results.win_rate,
          trades: results.total_trades
        }
      rescue => e
        puts "  Warning: #{strategy_name} failed: #{e.message}" if @options[:verbose]
        nil
      end.compact

      # Sort by return
      results_data.sort_by! { |r| -r[:return] }

      # Print comparison table
      puts "\n%-20s %10s %10s %10s %10s %10s" % %w[Strategy Return% Sharpe Drawdown% WinRate% Trades]
      puts "-" * 70
      results_data.each do |r|
        puts "%-20s %10.2f %10.2f %10.2f %10.2f %10d" % [
          r[:strategy],
          r[:return],
          r[:sharpe],
          r[:drawdown],
          r[:win_rate],
          r[:trades]
        ]
      end

      puts "\nBest Strategy: #{results_data.first[:strategy]} (#{results_data.first[:return].round(2)}% return)"
    end

    def resolve_strategy(name)
      case name.upcase
      when 'RSI'
        SQA::Strategy::RSI
      when 'SMA'
        SQA::Strategy::SMA
      when 'EMA'
        SQA::Strategy::EMA
      when 'MACD'
        SQA::Strategy::MACD
      when 'BOLLINGERBANDS'
        SQA::Strategy::BollingerBands
      when 'STOCHASTIC'
        SQA::Strategy::Stochastic
      when 'VOLUMEBREAKOUT'
        SQA::Strategy::VolumeBreakout
      when 'KBS'
        SQA::Strategy::KBS
      when 'CONSENSUS'
        SQA::Strategy::Consensus
      when 'RANDOM'
        SQA::Strategy::Random
      else
        raise "Unknown strategy: #{name}"
      end
    end
  end
end
