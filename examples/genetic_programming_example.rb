#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using Genetic Programming to Evolve Trading Strategy Parameters
#
# This example shows how to use SQA::GeneticProgram to automatically
# find optimal parameters for a trading strategy through evolution.

require 'sqa'

SQA.init

puts "=" * 60
puts "Genetic Programming Strategy Evolution"
puts "=" * 60
puts

# Load stock data
puts "Loading stock data for AAPL..."
stock = SQA::Stock.new(ticker: 'AAPL')
puts "Loaded #{stock.df.data.height} days of price history"
puts

# Define a simple RSI-based strategy factory
def create_rsi_strategy(period:, buy_threshold:, sell_threshold:)
  Class.new do
    define_singleton_method(:trade) do |vector|
      return :hold unless vector.respond_to?(:prices) && vector.prices&.size >= period

      # Calculate RSI with evolved period
      prices = vector.prices
      rsi = SQAI.rsi(prices, period: period)
      current_rsi = rsi.last

      # Use evolved thresholds
      if current_rsi < buy_threshold
        :buy
      elsif current_rsi > sell_threshold
        :sell
      else
        :hold
      end
    rescue => e
      puts "  Strategy error: #{e.message}"
      :hold
    end
  end
end

# Create genetic program
gp = SQA::GeneticProgram.new(
  stock: stock,
  population_size: 20,     # Small population for faster example
  generations: 10,         # Few generations for demo
  mutation_rate: 0.15,
  crossover_rate: 0.7
)

# Define gene constraints (parameter space to explore)
puts "Defining gene constraints..."
gp.define_genes(
  period: (7..30).to_a,           # RSI period: 7-30 days
  buy_threshold: (20..40).to_a,   # Buy when RSI below this
  sell_threshold: (60..80).to_a   # Sell when RSI above this
)
puts "  RSI Period: 7-30"
puts "  Buy Threshold: 20-40"
puts "  Sell Threshold: 60-80"
puts

# Define fitness function (how to evaluate a strategy)
puts "Defining fitness function (backtest total return)..."
gp.fitness do |genes|
  # Create strategy with these genes
  strategy = create_rsi_strategy(
    period: genes[:period],
    buy_threshold: genes[:buy_threshold],
    sell_threshold: genes[:sell_threshold]
  )

  # Backtest the strategy
  backtest = SQA::Backtest.new(
    stock: stock,
    strategy: strategy,
    initial_capital: 10_000.0,
    commission: 1.0
  )

  results = backtest.run
  results.total_return # Higher return = higher fitness
rescue => e
  puts "  Backtest failed for #{genes}: #{e.message}"
  -100.0 # Poor fitness for failed backtests
end
puts

# Run evolution
puts "Starting evolution..."
puts "-" * 60
best = gp.evolve
puts "-" * 60
puts

# Display results
puts "Evolution Results:"
puts "=" * 60
puts "Best Parameters Found:"
puts "  RSI Period: #{best.genes[:period]}"
puts "  Buy Threshold: #{best.genes[:buy_threshold]}"
puts "  Sell Threshold: #{best.genes[:sell_threshold]}"
puts "  Fitness (Total Return): #{best.fitness.round(2)}%"
puts

# Show evolution history
puts "Evolution History:"
puts "-" * 60
gp.history.each do |gen|
  puts "Generation #{gen[:generation]}: Best=#{gen[:best_fitness].round(2)}%, Avg=#{gen[:avg_fitness].round(2)}%"
end
puts

# Test the best strategy
puts "Testing Best Strategy:"
puts "-" * 60
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

puts "Backtest Results:"
puts "  Total Return: #{results.total_return.round(2)}%"
puts "  Sharpe Ratio: #{results.sharpe_ratio.round(2)}"
puts "  Max Drawdown: #{results.max_drawdown.round(2)}%"
puts "  Win Rate: #{results.win_rate.round(2)}%"
puts "  Total Trades: #{results.total_trades}"
puts

puts "Example complete!"
