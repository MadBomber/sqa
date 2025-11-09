#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base'

module Commands
  # Genetic command - Evolve strategy parameters with genetic programming
  class Genetic < Base
    private

    def default_options
      super.merge(
        population: 20,
        generations: 10,
        mutation_rate: 0.15,
        crossover_rate: 0.7,
        min_period: 7,
        max_period: 30,
        min_buy: 20,
        max_buy: 40,
        min_sell: 60,
        max_sell: 80
      )
    end

    def add_command_options(opts)
      opts.on('-p', '--population SIZE', Integer, 'Population size (default: 20)') do |size|
        @options[:population] = size
      end

      opts.on('-g', '--generations COUNT', Integer, 'Number of generations (default: 10)') do |count|
        @options[:generations] = count
      end

      opts.on('-m', '--mutation-rate RATE', Float, 'Mutation rate (default: 0.15)') do |rate|
        @options[:mutation_rate] = rate
      end

      opts.on('-c', '--crossover-rate RATE', Float, 'Crossover rate (default: 0.7)') do |rate|
        @options[:crossover_rate] = rate
      end
    end

    def banner
      <<~BANNER
        Usage: sqa-cli genetic [options]

        Evolve optimal trading strategy parameters using genetic algorithms.
        Evolves RSI strategy with period and buy/sell thresholds.

        Options:
      BANNER
    end

    public

    def execute
      stock = load_stock
      print_header "Genetic Programming: Evolving RSI Strategy for #{@options[:ticker]}"

      # Create genetic program
      gp = SQA::GeneticProgram.new(
        stock: stock,
        population_size: @options[:population],
        generations: @options[:generations],
        mutation_rate: @options[:mutation_rate],
        crossover_rate: @options[:crossover_rate]
      )

      # Define gene constraints
      puts "\nGene Constraints:"
      puts "  RSI Period: #{@options[:min_period]}-#{@options[:max_period]}"
      puts "  Buy Threshold: #{@options[:min_buy]}-#{@options[:max_buy]}"
      puts "  Sell Threshold: #{@options[:min_sell]}-#{@options[:max_sell]}"

      gp.define_genes(
        period: (@options[:min_period]..@options[:max_period]).to_a,
        buy_threshold: (@options[:min_buy]..@options[:max_buy]).to_a,
        sell_threshold: (@options[:min_sell]..@options[:max_sell]).to_a
      )

      # Define fitness function
      gp.fitness do |genes|
        strategy = create_rsi_strategy(
          period: genes[:period],
          buy_threshold: genes[:buy_threshold],
          sell_threshold: genes[:sell_threshold]
        )

        backtest = SQA::Backtest.new(
          stock: stock,
          strategy: strategy,
          initial_capital: 10_000.0,
          commission: 1.0
        )

        results = backtest.run
        results.total_return
      rescue => e
        puts "  Backtest failed for #{genes}: #{e.message}" if @options[:verbose]
        -100.0
      end

      # Run evolution
      print_section "Starting Evolution..."
      best = gp.evolve

      # Display results
      print_section "Evolution Results"
      puts "\nBest Parameters Found:"
      puts "  RSI Period: #{best.genes[:period]}"
      puts "  Buy Threshold: #{best.genes[:buy_threshold]}"
      puts "  Sell Threshold: #{best.genes[:sell_threshold]}"
      puts "  Fitness (Total Return): #{best.fitness.round(2)}%"

      # Show evolution history
      puts "\nEvolution History:"
      gp.history.each do |gen|
        puts "  Gen #{gen[:generation]}: Best=#{gen[:best_fitness].round(2)}%, Avg=#{gen[:avg_fitness].round(2)}%"
      end

      # Test best strategy
      print_section "Testing Best Strategy"
      best_strategy = create_rsi_strategy(
        period: best.genes[:period],
        buy_threshold: best.genes[:buy_threshold],
        sell_threshold: best.genes[:sell_threshold]
      )

      backtest = SQA::Backtest.new(
        stock: stock,
        strategy: best_strategy,
        initial_capital: 10_000.0,
        commission: 1.0
      )

      results = backtest.run
      print_results(results)
    end

    private

    def create_rsi_strategy(period:, buy_threshold:, sell_threshold:)
      Class.new do
        define_singleton_method(:trade) do |vector|
          return :hold unless vector.respond_to?(:prices) && vector.prices&.size >= period

          prices = vector.prices
          rsi = SQAI.rsi(prices, period: period)
          current_rsi = rsi.last

          if current_rsi < buy_threshold
            :buy
          elsif current_rsi > sell_threshold
            :sell
          else
            :hold
          end
        rescue
          :hold
        end
      end
    end
  end
end
