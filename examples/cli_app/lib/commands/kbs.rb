#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base'

module Commands
  # KBS command - Knowledge-Based Strategy with RETE
  class Kbs < Base
    private

    def default_options
      super.merge(
        rules: 'default',
        show_rules: false,
        show_facts: false,
        backtest: false
      )
    end

    def add_command_options(opts)
      opts.on('-r', '--rules TYPE', %w[default custom minimal], 'Rule set to use:', '  default, custom, minimal') do |rules|
        @options[:rules] = rules
      end

      opts.on('--show-rules', 'Display loaded rules') do
        @options[:show_rules] = true
      end

      opts.on('--show-facts', 'Display asserted facts') do
        @options[:show_facts] = true
      end

      opts.on('-b', '--backtest', 'Run backtest with strategy') do
        @options[:backtest] = true
      end
    end

    def banner
      <<~BANNER
        Usage: sqa-cli kbs [options]

        Run knowledge-based strategy using RETE forward-chaining inference.

        Options:
      BANNER
    end

    public

    def execute
      stock = load_stock
      print_header "Knowledge-Based Strategy (RETE) for #{@options[:ticker]}"

      # Create strategy with appropriate rules
      strategy = case @options[:rules]
                when 'default'
                  SQA::Strategy::KBS.new(load_defaults: true)
                when 'custom'
                  create_custom_strategy
                when 'minimal'
                  create_minimal_strategy
                else
                  SQA::Strategy::KBS.new(load_defaults: true)
                end

      # Show rules if requested
      if @options[:show_rules]
        print_section "Loaded Rules"
        strategy.print_rules
      end

      # Prepare data vector
      prices = stock.df["adj_close_price"].to_a
      volumes = stock.df["volume"].to_a
      highs = stock.df["high_price"].to_a
      lows = stock.df["low_price"].to_a

      require 'ostruct'
      vector = OpenStruct.new(
        prices: prices,
        volumes: volumes,
        highs: highs,
        lows: lows,
        rsi: SQAI.rsi(prices, period: 14),
        macd: SQAI.macd(prices),
        stoch_k: SQAI.stoch(highs, lows, prices).first,
        stoch_d: SQAI.stoch(highs, lows, prices).last,
        bb_upper: SQAI.bbands(prices).first,
        bb_middle: SQAI.bbands(prices)[1],
        bb_lower: SQAI.bbands(prices)[2]
      )

      # Execute strategy
      print_section "Executing Strategy"
      signal = strategy.execute(vector)
      puts "\nGenerated Signal: #{signal.to_s.upcase}"

      # Show facts if requested
      if @options[:show_facts]
        puts "\nAsserted Facts:"
        strategy.print_facts
      end

      # Run backtest if requested
      if @options[:backtest]
        print_section "Backtesting KBS Strategy"

        backtest = SQA::Backtest.new(
          stock: stock,
          strategy: strategy,
          initial_capital: 10_000.0,
          commission: 1.0
        )

        results = backtest.run
        print_results(results)
      end
    end

    private

    def create_custom_strategy
      strategy = SQA::Strategy::KBS.new(load_defaults: false)

      # Add custom rules
      strategy.add_rule :aggressive_buy do
        on :rsi, { level: :oversold }
        on :stochastic, { zone: :oversold }
        on :bollinger, { position: :below }
        perform do
          kb.assert(:signal, { action: :buy, confidence: :high, reason: :triple_confirmation })
        end
      end

      strategy.add_rule :conservative_sell do
        on :rsi, { level: :overbought }
        on :trend, { short_term: :down }
        perform do
          kb.assert(:signal, { action: :sell, confidence: :medium, reason: :overbought_downtrend })
        end
      end

      strategy.add_rule :volume_breakout do
        on :trend, { short_term: :up, strength: :strong }
        on :volume, { level: :high }
        perform do
          kb.assert(:signal, { action: :buy, confidence: :high, reason: :volume_breakout })
        end
      end

      strategy
    end

    def create_minimal_strategy
      strategy = SQA::Strategy::KBS.new(load_defaults: false)

      strategy.add_rule :simple_rsi do
        on :rsi, { level: :oversold }
        perform do
          kb.assert(:signal, { action: :buy, confidence: :medium, reason: :rsi_oversold })
        end
      end

      strategy.add_rule :simple_macd do
        on :macd, { crossover: :bullish }
        perform do
          kb.assert(:signal, { action: :buy, confidence: :medium, reason: :macd_bullish })
        end
      end

      strategy
    end
  end
end
