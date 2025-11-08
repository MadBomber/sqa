# frozen_string_literal: true

=begin

Genetic Programming for Trading Strategy Evolution

This module implements a genetic algorithm to evolve trading strategy parameters.
It optimizes indicator parameters (like RSI periods, MA lengths, etc.) to find
profitable trading strategies through natural selection.

Key Concepts:
- Individual: A set of strategy parameters (chromosome)
- Population: Collection of individuals
- Fitness: Profitability measured by backtesting
- Selection: Choosing best individuals to reproduce
- Crossover: Combining parameters from two parent strategies
- Mutation: Random parameter changes for diversity

Example:
  gp = SQA::GeneticProgram.new(
    stock: stock,
    population_size: 50,
    generations: 100,
    mutation_rate: 0.1
  )

  best_strategy = gp.evolve do |params|
    # Define how to evaluate fitness with given parameters
    # params might be { indicator: :rsi, period: 14, buy_threshold: 30, sell_threshold: 70 }
  end

=end

module SQA
  class GeneticProgram
    # Represents an individual trading strategy with specific parameters
    class Individual
      attr_accessor :genes, :fitness

      def initialize(genes: {}, fitness: nil)
        @genes = genes.dup
        @fitness = fitness
      end

      def clone
        Individual.new(genes: @genes.dup, fitness: @fitness)
      end

      def to_s
        "Individual(fitness=#{fitness&.round(2)}, genes=#{genes})"
      end
    end

    attr_reader :stock, :population, :best_individual, :generation, :history
    attr_accessor :population_size, :generations, :mutation_rate, :crossover_rate, :elitism_count

    def initialize(stock:, population_size: 50, generations: 100, mutation_rate: 0.15, crossover_rate: 0.7, elitism_count: 2)
      @stock = stock
      @population_size = population_size
      @generations = generations
      @mutation_rate = mutation_rate
      @crossover_rate = crossover_rate
      @elitism_count = elitism_count

      @population = []
      @best_individual = nil
      @generation = 0
      @history = []
      @gene_constraints = {}
      @fitness_evaluator = nil
    end

    # Define the parameter space for evolution
    #
    # Example:
    #   gp.define_genes(
    #     indicator: [:rsi, :macd, :stoch],
    #     period: (5..30).to_a,
    #     buy_threshold: (20..40).to_a,
    #     sell_threshold: (60..80).to_a
    #   )
    def define_genes(**constraints)
      @gene_constraints = constraints
      self
    end

    # Define how to evaluate fitness for an individual
    #
    # The block receives an individual's genes hash and should return
    # a numeric fitness value (higher is better)
    #
    # Example:
    #   gp.fitness do |genes|
    #     backtest = SQA::Backtest.new(
    #       stock: stock,
    #       strategy: create_strategy_from_genes(genes),
    #       initial_capital: 10_000
    #     )
    #     results = backtest.run
    #     results.total_return # Higher return = higher fitness
    #   end
    def fitness(&block)
      @fitness_evaluator = block
      self
    end

    # Run the genetic algorithm evolution
    def evolve
      raise "Gene constraints not defined. Call define_genes first." if @gene_constraints.empty?
      raise "Fitness evaluator not defined. Call fitness with a block." unless @fitness_evaluator

      initialize_population

      @generations.times do |gen|
        @generation = gen + 1

        # Evaluate fitness for each individual
        evaluate_population

        # Track best individual
        current_best = @population.max_by(&:fitness)
        if @best_individual.nil? || current_best.fitness > @best_individual.fitness
          @best_individual = current_best.clone
        end

        # Record history
        avg_fitness = @population.sum(&:fitness) / @population.size.to_f
        @history << {
          generation: @generation,
          best_fitness: current_best.fitness,
          avg_fitness: avg_fitness,
          best_genes: current_best.genes.dup
        }

        # Print progress
        puts "Generation #{@generation}: Best=#{current_best.fitness.round(2)}%, Avg=#{avg_fitness.round(2)}%"

        # Create next generation
        @population = create_next_generation
      end

      # Final evaluation
      evaluate_population
      current_best = @population.max_by(&:fitness)
      if @best_individual.nil? || current_best.fitness > @best_individual.fitness
        @best_individual = current_best.clone
      end

      puts "\nEvolution complete!"
      puts "Best individual: #{@best_individual}"

      @best_individual
    end

    private

    # Initialize population with random individuals
    def initialize_population
      @population = Array.new(@population_size) do
        Individual.new(genes: random_genes)
      end
    end

    # Generate random gene values within constraints
    def random_genes
      genes = {}
      @gene_constraints.each do |gene_name, possible_values|
        genes[gene_name] = Array(possible_values).sample
      end
      genes
    end

    # Evaluate fitness for all individuals in population
    def evaluate_population
      @population.each do |individual|
        next if individual.fitness # Already evaluated

        begin
          individual.fitness = @fitness_evaluator.call(individual.genes)
        rescue => e
          # If evaluation fails, assign very poor fitness
          individual.fitness = -Float::INFINITY
          puts "  Warning: Fitness evaluation failed for #{individual.genes}: #{e.message}"
        end
      end
    end

    # Create next generation through selection, crossover, and mutation
    def create_next_generation
      new_population = []

      # Elitism: keep best individuals
      sorted = @population.sort_by(&:fitness).reverse
      @elitism_count.times do |i|
        new_population << sorted[i].clone if sorted[i]
      end

      # Fill rest of population through crossover and mutation
      while new_population.size < @population_size
        # Selection
        parent1 = tournament_selection
        parent2 = tournament_selection

        # Crossover
        if rand < @crossover_rate
          child1, child2 = crossover(parent1, parent2)
        else
          child1, child2 = parent1.clone, parent2.clone
        end

        # Mutation
        mutate(child1) if rand < @mutation_rate
        mutate(child2) if rand < @mutation_rate

        # Reset fitness for new individuals
        child1.fitness = nil
        child2.fitness = nil

        new_population << child1
        new_population << child2 if new_population.size < @population_size
      end

      new_population[0...@population_size]
    end

    # Tournament selection: pick best from random sample
    def tournament_selection(tournament_size: 3)
      tournament = @population.sample(tournament_size)
      tournament.max_by(&:fitness)
    end

    # Single-point crossover: combine genes from two parents
    def crossover(parent1, parent2)
      child1_genes = {}
      child2_genes = {}

      @gene_constraints.keys.each do |gene_name|
        if rand < 0.5
          child1_genes[gene_name] = parent1.genes[gene_name]
          child2_genes[gene_name] = parent2.genes[gene_name]
        else
          child1_genes[gene_name] = parent2.genes[gene_name]
          child2_genes[gene_name] = parent1.genes[gene_name]
        end
      end

      [Individual.new(genes: child1_genes), Individual.new(genes: child2_genes)]
    end

    # Mutation: randomly change some genes
    def mutate(individual)
      @gene_constraints.each do |gene_name, possible_values|
        if rand < 0.3 # 30% chance to mutate each gene
          individual.genes[gene_name] = Array(possible_values).sample
        end
      end
    end
  end
end
