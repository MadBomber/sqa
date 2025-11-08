# test/pattern_context_test.rb
# frozen_string_literal: true

require_relative 'test_helper'

class PatternContextTest < Minitest::Test
  def setup
    @context = SQA::StrategyGenerator::PatternContext.new
  end

  def test_initialization
    assert @context.is_a?(SQA::StrategyGenerator::PatternContext)
    assert_nil @context.market_regime
    assert_equal [], @context.valid_months
    assert_equal [], @context.valid_quarters
    assert_nil @context.discovered_period
    assert_nil @context.validation_period
    assert_nil @context.stability_score
    assert_nil @context.sector
    assert_nil @context.volatility_regime
  end

  def test_valid_returns_false_empty
    refute @context.valid?
  end

  def test_valid_returns_true_with_regime
    @context.market_regime = :bull
    assert @context.valid?
  end

  def test_valid_returns_true_with_months
    @context.valid_months = [10, 11, 12]
    assert @context.valid?
  end

  def test_valid_returns_true_with_sector
    @context.sector = :technology
    assert @context.valid?
  end

  def test_summary_empty
    summary = @context.summary
    assert_equal "", summary
  end

  def test_summary_with_regime
    @context.market_regime = :bull
    summary = @context.summary
    assert_equal "bull", summary
  end

  def test_summary_with_months
    @context.valid_months = [10, 11, 12]
    summary = @context.summary
    assert_equal "months:10,11,12", summary
  end

  def test_summary_with_quarters
    @context.valid_quarters = [1, 4]
    summary = @context.summary
    assert_equal "Q1,4", summary
  end

  def test_summary_with_sector
    @context.sector = :technology
    summary = @context.summary
    assert_equal "technology", summary
  end

  def test_summary_combined
    @context.market_regime = :bull
    @context.valid_months = [10, 11, 12]
    @context.valid_quarters = [4]
    @context.sector = :technology

    summary = @context.summary
    assert_includes summary, "bull"
    assert_includes summary, "months:10,11,12"
    assert_includes summary, "Q4"
    assert_includes summary, "technology"
  end

  def test_valid_for_all_match
    @context.market_regime = :bull
    @context.valid_months = [12]
    @context.sector = :technology

    result = @context.valid_for?(
      date: Date.new(2024, 12, 15),
      regime: :bull,
      sector: :technology
    )

    assert result
  end

  def test_valid_for_wrong_regime
    @context.market_regime = :bull

    result = @context.valid_for?(regime: :bear)

    refute result
  end

  def test_valid_for_wrong_sector
    @context.sector = :technology

    result = @context.valid_for?(sector: :finance)

    refute result
  end

  def test_valid_for_wrong_month
    @context.valid_months = [10, 11, 12]

    result = @context.valid_for?(date: Date.new(2024, 6, 15))

    refute result
  end

  def test_valid_for_wrong_quarter
    @context.valid_quarters = [1, 4]

    result = @context.valid_for?(date: Date.new(2024, 6, 15))  # Q2

    refute result
  end

  def test_valid_for_no_constraints
    # Empty context should match anything
    result = @context.valid_for?(
      date: Date.new(2024, 6, 15),
      regime: :bear,
      sector: :finance
    )

    assert result
  end

  def test_valid_for_partial_match
    @context.market_regime = :bull
    # No month/sector constraints

    result = @context.valid_for?(
      date: Date.new(2024, 6, 15),
      regime: :bull,
      sector: :finance
    )

    assert result
  end

  def test_valid_for_december_q4
    @context.valid_months = [12]

    result = @context.valid_for?(date: Date.new(2024, 12, 31))
    assert result

    # Check quarter is calculated correctly
    @context.valid_months = []
    @context.valid_quarters = [4]

    result = @context.valid_for?(date: Date.new(2024, 12, 1))
    assert result
  end

  def test_valid_for_january_q1
    @context.valid_quarters = [1]

    result = @context.valid_for?(date: Date.new(2024, 1, 15))
    assert result

    result = @context.valid_for?(date: Date.new(2024, 4, 15))
    refute result
  end
end

class PatternWithContextTest < Minitest::Test
  def setup
    @pattern = SQA::StrategyGenerator::Pattern.new(
      conditions: { rsi: :oversold, trend: :up }
    )
  end

  def test_pattern_has_context
    assert @pattern.respond_to?(:context)
    assert @pattern.context.is_a?(SQA::StrategyGenerator::PatternContext)
  end

  def test_pattern_to_s_without_context
    str = @pattern.to_s
    refute_includes str, "["
  end

  def test_pattern_to_s_with_context
    @pattern.context.market_regime = :bull
    @pattern.context.sector = :technology

    str = @pattern.to_s
    assert_includes str, "["
    assert_includes str, "bull"
    assert_includes str, "technology"
  end

  def test_pattern_context_independence
    pattern1 = SQA::StrategyGenerator::Pattern.new
    pattern2 = SQA::StrategyGenerator::Pattern.new

    pattern1.context.market_regime = :bull
    pattern2.context.market_regime = :bear

    assert_equal :bull, pattern1.context.market_regime
    assert_equal :bear, pattern2.context.market_regime
  end
end

class StrategyGeneratorContextMethodsTest < Minitest::Test
  def test_discover_context_aware_patterns_exists
    skip "Requires stock object" unless ENV['RUN_INTEGRATION_TESTS']

    # Just verify method exists
    generator = Object.new
    generator.extend(SQA::StrategyGenerator)

    assert_respond_to generator, :discover_context_aware_patterns
  end

  def test_walk_forward_validate_exists
    skip "Requires stock object" unless ENV['RUN_INTEGRATION_TESTS']

    generator = Object.new
    generator.extend(SQA::StrategyGenerator)

    assert_respond_to generator, :walk_forward_validate
  end
end
