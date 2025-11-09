#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

module Commands
  # Base class for all CLI commands
  class Base
    attr_reader :options, :args

    def initialize(args)
      @args = args
      @options = default_options
      parse_options
    end

    def execute
      raise NotImplementedError, "Subclass must implement #execute"
    end

    private

    def default_options
      {
        ticker: 'AAPL',
        verbose: false
      }
    end

    def parse_options
      OptionParser.new do |opts|
        opts.banner = banner

        # Common options
        opts.on('-t', '--ticker SYMBOL', 'Stock ticker symbol (default: AAPL)') do |ticker|
          @options[:ticker] = ticker.upcase
        end

        opts.on('-v', '--verbose', 'Verbose output') do
          @options[:verbose] = true
        end

        opts.on('-h', '--help', 'Show this help message') do
          puts opts
          exit
        end

        # Add command-specific options
        add_command_options(opts)
      end.parse!(@args)
    rescue OptionParser::InvalidOption => e
      puts "Error: #{e.message}"
      puts "\nRun with --help for usage information."
      exit 1
    end

    def add_command_options(opts)
      # Override in subclasses
    end

    def banner
      "Usage: sqa-cli #{command_name} [options]"
    end

    def command_name
      self.class.name.split('::').last.downcase
    end

    def load_stock
      # Load SQA on first use
      require 'sqa' unless defined?(SQA)

      puts "Loading stock data for #{@options[:ticker]}..." if @options[:verbose]
      SQA.init unless defined?(SQA::Stock)
      stock = SQA::Stock.new(ticker: @options[:ticker])
      puts "Loaded #{stock.df.data.height} days of price history" if @options[:verbose]
      stock
    rescue => e
      puts "Error loading stock data: #{e.message}"
      exit 1
    end

    def print_header(text)
      puts "\n" + "=" * 70
      puts text
      puts "=" * 70
    end

    def print_section(text)
      puts "\n" + "-" * 70
      puts text
      puts "-" * 70
    end

    def print_results(results)
      puts "\nBacktest Results:"
      puts "  Total Return: #{results.total_return.round(2)}%"
      puts "  Annualized Return: #{results.annualized_return.round(2)}%"
      puts "  Sharpe Ratio: #{results.sharpe_ratio.round(2)}"
      puts "  Max Drawdown: #{results.max_drawdown.round(2)}%"
      puts "  Win Rate: #{results.win_rate.round(2)}%"
      puts "  Total Trades: #{results.total_trades}"
      puts "  Profit Factor: #{results.profit_factor.round(2)}"
    end
  end
end
