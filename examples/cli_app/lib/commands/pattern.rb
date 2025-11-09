#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base'

module Commands
  # Pattern command - Discover profitable trading patterns
  class Pattern < Base
    private

    def default_options
      super.merge(
        min_gain: 10.0,
        fpop: 10,
        min_frequency: 3,
        inflection_window: 3,
        max_patterns: 10,
        export: nil,
        generate: false
      )
    end

    def add_command_options(opts)
      opts.on('-g', '--min-gain PERCENT', Float, 'Minimum gain percent (default: 10.0)') do |gain|
        @options[:min_gain] = gain
      end

      opts.on('-f', '--fpop DAYS', Integer, 'Future period of performance in days (default: 10)') do |fpop|
        @options[:fpop] = fpop
      end

      opts.on('-m', '--min-frequency COUNT', Integer, 'Minimum pattern frequency (default: 3)') do |freq|
        @options[:min_frequency] = freq
      end

      opts.on('-w', '--window DAYS', Integer, 'Inflection detection window (default: 3)') do |window|
        @options[:inflection_window] = window
      end

      opts.on('-n', '--max-patterns COUNT', Integer, 'Max patterns to display (default: 10)') do |max|
        @options[:max_patterns] = max
      end

      opts.on('-e', '--export FILE', 'Export patterns to CSV file') do |file|
        @options[:export] = file
      end

      opts.on('--generate', 'Generate and backtest strategies from patterns') do
        @options[:generate] = true
      end
    end

    def banner
      <<~BANNER
        Usage: sqa-cli pattern [options]

        Discover profitable trading patterns by reverse-engineering historical trades.
        Identifies indicator combinations at inflection points that preceded gains.

        Options:
      BANNER
    end

    public

    def execute
      stock = load_stock
      print_header "Pattern Discovery for #{@options[:ticker]}"

      puts "\nParameters:"
      puts "  Minimum Gain: #{@options[:min_gain]}%"
      puts "  FPOP (Future Period): #{@options[:fpop]} days"
      puts "  Minimum Frequency: #{@options[:min_frequency]}"
      puts "  Inflection Window: #{@options[:inflection_window]} days"

      # Create strategy generator
      generator = SQA::StrategyGenerator.new(
        stock: stock,
        min_gain_percent: @options[:min_gain],
        fpop: @options[:fpop],
        inflection_window: @options[:inflection_window]
      )

      # Discover patterns
      print_section "Discovering Patterns..."
      patterns = generator.discover_patterns(min_pattern_frequency: @options[:min_frequency])

      if patterns.empty?
        puts "\nNo patterns found with current parameters."
        puts "Try adjusting --min-gain, --fpop, or --min-frequency"
        return
      end

      # Print patterns
      print_section "Discovered Patterns"
      generator.print_patterns(max_patterns: @options[:max_patterns])

      # Export if requested
      if @options[:export]
        generator.export_patterns(@options[:export])
        puts "\nPatterns exported to: #{@options[:export]}"
      end

      # Generate and test strategies if requested
      if @options[:generate]
        generate_strategies(generator, stock)
      end
    end

    private

    def generate_strategies(generator, stock)
      print_section "Generating Strategies from Top Patterns"

      strategies = generator.generate_strategies(top_n: 3, strategy_type: :class)

      if strategies.empty?
        puts "No strategies could be generated"
        return
      end

      puts "\nGenerated #{strategies.size} strategies\n"

      strategies.each_with_index do |strategy, i|
        puts "\n#{"-" * 70}"
        puts "Strategy ##{i + 1}"
        puts "Pattern: #{strategy.pattern}"
        puts

        backtest = SQA::Backtest.new(
          stock: stock,
          strategy: strategy,
          initial_capital: 10_000.0,
          commission: 1.0
        )

        results = backtest.run

        puts "Backtest Results:"
        puts "  Total Return: #{results.total_return.round(2)}%"
        puts "  Sharpe Ratio: #{results.sharpe_ratio.round(2)}"
        puts "  Max Drawdown: #{results.max_drawdown.round(2)}%"
        puts "  Win Rate: #{results.win_rate.round(2)}%"
        puts "  Total Trades: #{results.total_trades}"
      end
    end
  end
end
