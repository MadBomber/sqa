#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base'

module Commands
  # Stream command - Simulate real-time price streaming
  class Stream < Base
    private

    def default_options
      super.merge(
        strategies: ['RSI'],
        window: 100,
        updates: 50
      )
    end

    def add_command_options(opts)
      opts.on('-s', '--strategies LIST', Array, 'Strategies to run (comma-separated)') do |strategies|
        @options[:strategies] = strategies
      end

      opts.on('-w', '--window SIZE', Integer, 'Rolling window size (default: 100)') do |window|
        @options[:window] = window
      end

      opts.on('-u', '--updates COUNT', Integer, 'Number of price updates to simulate (default: 50)') do |updates|
        @options[:updates] = updates
      end
    end

    def banner
      <<~BANNER
        Usage: sqa-cli stream [options]

        Simulate real-time price streaming with strategy execution.
        Uses historical data to simulate live price updates.

        Options:
      BANNER
    end

    public

    def execute
      stock = load_stock
      print_header "Real-Time Streaming Simulation for #{@options[:ticker]}"

      # Resolve strategy classes
      strategy_classes = @options[:strategies].map do |name|
        resolve_strategy(name)
      end

      puts "\nConfiguration:"
      puts "  Strategies: #{@options[:strategies].join(', ')}"
      puts "  Window Size: #{@options[:window]}"
      puts "  Simulated Updates: #{@options[:updates]}"

      # Create stream
      stream = SQA::Stream.new(
        ticker: @options[:ticker],
        strategies: strategy_classes,
        window_size: @options[:window]
      )

      # Set up signal callback
      signals_received = []
      stream.on_signal do |signal, data|
        signals_received << { signal: signal, price: data[:price], time: Time.now }
        puts "  📊 Signal: #{signal.to_s.upcase} at $#{data[:price].round(2)} (#{data[:strategy]})"
      end

      # Get historical prices
      prices = stock.df["adj_close_price"].to_a
      volumes = stock.df["volume"].to_a

      # Take last N points for simulation
      start_idx = [prices.size - @options[:updates] - @options[:window], 0].max
      sim_prices = prices[start_idx..]
      sim_volumes = volumes[start_idx..]

      print_section "Starting Stream..."

      # Simulate price updates
      sim_prices.each_with_index do |price, idx|
        volume = sim_volumes[idx] || 1_000_000

        stream.update(
          price: price,
          volume: volume,
          timestamp: Time.now
        )

        # Show progress every 10 updates
        if idx % 10 == 0 && @options[:verbose]
          puts "  Update #{idx + 1}/#{sim_prices.size}: Price=$#{price.round(2)}, Volume=#{volume}"
        end
      end

      # Summary
      print_section "Streaming Summary"
      puts "\nTotal Updates: #{sim_prices.size}"
      puts "Signals Generated: #{signals_received.size}"

      if signals_received.any?
        puts "\nSignal Breakdown:"
        [:buy, :sell, :hold].each do |signal|
          count = signals_received.count { |s| s[:signal] == signal }
          puts "  #{signal.to_s.upcase}: #{count}"
        end

        puts "\nLast 5 Signals:"
        signals_received.last(5).each do |s|
          puts "  #{s[:signal].to_s.upcase} at $#{s[:price].round(2)}"
        end
      end
    end

    private

    def resolve_strategy(name)
      case name.upcase
      when 'RSI'
        SQA::Strategy::RSI
      when 'MACD'
        SQA::Strategy::MACD
      when 'KBS'
        SQA::Strategy::KBS
      when 'CONSENSUS'
        SQA::Strategy::Consensus
      else
        raise "Unknown strategy: #{name}"
      end
    end
  end
end
