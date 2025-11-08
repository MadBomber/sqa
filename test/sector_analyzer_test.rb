# test/sector_analyzer_test.rb
# frozen_string_literal: true

require_relative 'test_helper'
require 'fileutils'
require 'tmpdir'

class SectorAnalyzerTest < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir
    @analyzer = SQA::SectorAnalyzer.new(db_dir: @test_dir)
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if @test_dir && File.exist?(@test_dir)
  end

  def test_initialization
    assert @analyzer.is_a?(SQA::SectorAnalyzer)
    assert @analyzer.blackboards.is_a?(Hash)
    assert @analyzer.stocks_by_sector.is_a?(Hash)

    # Should have blackboards for all sectors
    SQA::SectorAnalyzer::SECTORS.keys.each do |sector|
      assert @analyzer.blackboards.key?(sector)
      assert @analyzer.blackboards[sector].is_a?(KBS::Blackboard::Engine)
    end
  end

  def test_sector_constants
    assert SQA::SectorAnalyzer::SECTORS.is_a?(Hash)
    assert_includes SQA::SectorAnalyzer::SECTORS.keys, :technology
    assert_includes SQA::SectorAnalyzer::SECTORS.keys, :finance
    assert_includes SQA::SectorAnalyzer::SECTORS.keys, :healthcare
    assert_includes SQA::SectorAnalyzer::SECTORS.keys, :energy

    # Technology sector should have known stocks
    assert_includes SQA::SectorAnalyzer::SECTORS[:technology], 'AAPL'
    assert_includes SQA::SectorAnalyzer::SECTORS[:technology], 'MSFT'
  end

  def test_add_stock_string
    ticker = @analyzer.add_stock('AAPL', sector: :technology)

    assert_equal 'AAPL', ticker
    assert_includes @analyzer.stocks_by_sector[:technology], 'AAPL'
  end

  def test_add_stock_invalid_sector
    assert_raises(ArgumentError) do
      @analyzer.add_stock('AAPL', sector: :invalid_sector)
    end
  end

  def test_add_stock_registers_in_blackboard
    @analyzer.add_stock('AAPL', sector: :technology)

    kb = @analyzer.blackboards[:technology]
    stock_facts = kb.working_memory.facts.select { |f| f.type == :stock_registered }

    assert stock_facts.size > 0
    apple_fact = stock_facts.find { |f| f.attributes[:ticker] == 'AAPL' }
    assert apple_fact
    assert_equal :technology, apple_fact.attributes[:sector]
  end

  def test_add_stock_no_duplicates
    @analyzer.add_stock('AAPL', sector: :technology)
    @analyzer.add_stock('AAPL', sector: :technology)

    # Should only appear once
    assert_equal 1, @analyzer.stocks_by_sector[:technology].count('AAPL')
  end

  def test_query_sector
    @analyzer.add_stock('AAPL', sector: :technology)
    @analyzer.add_stock('MSFT', sector: :technology)

    results = @analyzer.query_sector(:technology, :stock_registered)

    assert results.size >= 2
    tickers = results.map { |f| f.attributes[:ticker] }
    assert_includes tickers, 'AAPL'
    assert_includes tickers, 'MSFT'
  end

  def test_query_sector_with_pattern
    @analyzer.add_stock('AAPL', sector: :technology)
    @analyzer.add_stock('MSFT', sector: :technology)

    results = @analyzer.query_sector(:technology, :stock_registered, { ticker: 'AAPL' })

    assert_equal 1, results.size
    assert_equal 'AAPL', results.first.attributes[:ticker]
  end

  def test_discover_sector_patterns
    skip "Requires stock object and network access" unless ENV['RUN_INTEGRATION_TESTS']

    # This would require real stock objects
    # Just test the structure for now
    assert_respond_to @analyzer, :discover_sector_patterns
  end

  def test_detect_sector_regime
    skip "Requires stock object" unless ENV['RUN_INTEGRATION_TESTS']

    # This would require real stock objects
    # Just test the structure for now
    assert_respond_to @analyzer, :detect_sector_regime
  end

  def test_print_sector_summary
    @analyzer.add_stock('AAPL', sector: :technology)

    # Should not raise error
    assert_silent do
      capture_io do
        @analyzer.print_sector_summary(:technology)
      end
    end
  end

  def test_blackboard_persistence
    # Add stock
    @analyzer.add_stock('AAPL', sector: :technology)

    # Create new analyzer with same db_dir
    analyzer2 = SQA::SectorAnalyzer.new(db_dir: @test_dir)

    # Should be able to query persisted data
    results = analyzer2.query_sector(:technology, :stock_registered, { ticker: 'AAPL' })

    assert results.size > 0, "Blackboard data should persist"
  end

  def test_multiple_sectors
    @analyzer.add_stock('AAPL', sector: :technology)
    @analyzer.add_stock('JPM', sector: :finance)
    @analyzer.add_stock('JNJ', sector: :healthcare)

    assert_equal 1, @analyzer.stocks_by_sector[:technology].size
    assert_equal 1, @analyzer.stocks_by_sector[:finance].size
    assert_equal 1, @analyzer.stocks_by_sector[:healthcare].size

    # Each sector should have its own facts
    tech_facts = @analyzer.query_sector(:technology, :stock_registered)
    finance_facts = @analyzer.query_sector(:finance, :stock_registered)
    health_facts = @analyzer.query_sector(:healthcare, :stock_registered)

    assert tech_facts.any? { |f| f.attributes[:ticker] == 'AAPL' }
    assert finance_facts.any? { |f| f.attributes[:ticker] == 'JPM' }
    assert health_facts.any? { |f| f.attributes[:ticker] == 'JNJ' }

    # Cross-sector isolation
    refute tech_facts.any? { |f| f.attributes[:ticker] == 'JPM' }
    refute finance_facts.any? { |f| f.attributes[:ticker] == 'AAPL' }
  end
end
