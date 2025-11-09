#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'pathname'

# Add lib to load path for SQA (but don't load it yet)
$LOAD_PATH.unshift(File.expand_path('../../../lib', __dir__))

# Main CLI class
class CLI
  COMMANDS = %w[backtest genetic pattern kbs stream analyze optimize help].freeze

  def self.run(args)
    new(args).execute
  end

  def initialize(args)
    @args = args
    @command = args.shift
  end

  def execute
    # Show help if no command provided
    if @command.nil? || @command == 'help' || @command == '--help' || @command == '-h'
      show_help
      return
    end

    # Validate command
    unless COMMANDS.include?(@command)
      puts "Error: Unknown command '#{@command}'"
      puts "\nRun 'sqa-cli help' for usage information."
      exit 1
    end

    # Load and execute command
    require_relative "commands/#{@command}"
    command_class = Object.const_get("Commands::#{camelize(@command)}")
    command_class.new(@args).execute
  rescue LoadError => e
    puts "Error: Command '#{@command}' not yet implemented"
    puts "Details: #{e.message}"
    exit 1
  rescue => e
    puts "Error executing command: #{e.message}"
    puts e.backtrace.first(5)
    exit 1
  end

  private

  def show_help
    puts <<~HELP
      SQA CLI - Simple Qualitative Analysis Command Line Interface

      Usage:
        sqa-cli <command> [options]

      Available Commands:
        backtest     Run strategy backtests on historical data
        genetic      Evolve strategy parameters using genetic programming
        pattern      Discover profitable trading patterns
        kbs          Run knowledge-based strategy with rules
        stream       Simulate real-time price streaming
        analyze      Analyze stocks with FPL, regime, seasonal analysis
        optimize     Portfolio optimization and risk management
        help         Show this help message

      Common Options:
        -t, --ticker SYMBOL      Stock ticker symbol (default: AAPL)
        -h, --help               Show command-specific help

      Examples:
        # Backtest RSI strategy on AAPL
        sqa-cli backtest --ticker AAPL --strategy RSI

        # Evolve strategy parameters with genetic programming
        sqa-cli genetic --ticker AAPL --generations 50 --population 30

        # Discover patterns that lead to 10%+ gains
        sqa-cli pattern --ticker AAPL --min-gain 10 --fpop 10

        # Run knowledge-based strategy
        sqa-cli kbs --ticker AAPL --rules default

        # Analyze stock with multiple methods
        sqa-cli analyze --ticker AAPL --methods regime,seasonal,fpop

        # Portfolio optimization
        sqa-cli optimize --tickers AAPL,MSFT,GOOGL --method sharpe

      For command-specific help:
        sqa-cli <command> --help

      Documentation:
        https://github.com/MadBomber/sqa
    HELP
  end

  def camelize(string)
    string.split('_').map(&:capitalize).join
  end
end
