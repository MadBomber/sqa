require_relative 'test_helper'

class GeneticProgramTest < Minitest::Test
  def setup
    skip "Requires network access for stock data" unless ENV['RUN_INTEGRATION_TESTS']

    SQA.init
    @stock = SQA::Stock.new(ticker: 'AAPL')
  end

  def test_initialization
    skip "Requires network access" unless ENV['RUN_INTEGRATION_TESTS']

    gp = SQA::GeneticProgram.new(
      stock: @stock,
      population_size: 10,
      generations: 5
    )

    assert_equal @stock, gp.stock
    assert_equal 10, gp.population_size
    assert_equal 5, gp.generations
  end

  def test_individual_creation
    individual = SQA::GeneticProgram::Individual.new(
      genes: { period: 14, threshold: 30 },
      fitness: 10.5
    )

    assert_equal 14, individual.genes[:period]
    assert_equal 30, individual.genes[:threshold]
    assert_equal 10.5, individual.fitness
  end

  def test_individual_clone
    individual = SQA::GeneticProgram::Individual.new(
      genes: { period: 14 },
      fitness: 5.0
    )

    clone = individual.clone

    assert_equal individual.genes, clone.genes
    assert_equal individual.fitness, clone.fitness
    refute_same individual.genes, clone.genes # Different object
  end

  def test_define_genes
    skip "Requires network access" unless ENV['RUN_INTEGRATION_TESTS']

    gp = SQA::GeneticProgram.new(stock: @stock)

    gp.define_genes(
      period: (5..20).to_a,
      threshold: (10..50).to_a
    )

    assert_equal 2, gp.instance_variable_get(:@gene_constraints).size
  end

  def test_fitness_evaluator
    skip "Requires network access" unless ENV['RUN_INTEGRATION_TESTS']

    gp = SQA::GeneticProgram.new(stock: @stock)

    fitness_called = false
    gp.fitness do |genes|
      fitness_called = true
      10.0
    end

    gp.define_genes(period: [14])

    # This would call fitness evaluator
    # gp.evolve

    assert gp.instance_variable_get(:@fitness_evaluator)
  end

  def test_evolve_requires_genes
    skip "Requires network access" unless ENV['RUN_INTEGRATION_TESTS']

    gp = SQA::GeneticProgram.new(stock: @stock, population_size: 5, generations: 2)

    assert_raises(RuntimeError) { gp.evolve }
  end

  def test_evolve_requires_fitness
    skip "Requires network access" unless ENV['RUN_INTEGRATION_TESTS']

    gp = SQA::GeneticProgram.new(stock: @stock, population_size: 5, generations: 2)
    gp.define_genes(period: [10, 14, 20])

    assert_raises(RuntimeError) { gp.evolve }
  end

  def test_evolution_history_tracking
    skip "Requires network access" unless ENV['RUN_INTEGRATION_TESTS']
    skip "Long running test"

    gp = SQA::GeneticProgram.new(stock: @stock, population_size: 5, generations: 3)
    gp.define_genes(period: [10, 14, 20])
    gp.fitness { |genes| rand(0.0..10.0) }

    gp.evolve

    assert_equal 3, gp.history.size
    assert gp.best_individual
  end
end
