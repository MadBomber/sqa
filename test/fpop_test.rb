# test/fpop_test.rb
# frozen_string_literal: true

require_relative 'test_helper'

class FPOPTest < Minitest::Test
  def setup
    @simple_prices = [100, 105, 110, 108, 112, 115, 120]
    @volatile_prices = [100, 110, 95, 120, 100, 130, 110]
  end

  def test_fpl_basic
    fpl_results = SQA::FPOP.fpl(@simple_prices, fpop: 3)

    assert_instance_of Array, fpl_results
    assert_equal @simple_prices.size - 3, fpl_results.size

    # First point: 100 -> looking at [105, 110, 108]
    # Min delta: (105-100)/100 = 5%
    # Max delta: (110-100)/100 = 10%
    min_delta, max_delta = fpl_results.first
    assert_in_delta 5.0, min_delta, 0.1
    assert_in_delta 10.0, max_delta, 0.1
  end

  def test_fpl_with_decline
    fpl_results = SQA::FPOP.fpl(@volatile_prices, fpop: 2)

    # First point: 100 -> [110, 95]
    # Min: (95-100)/100 = -5%
    # Max: (110-100)/100 = 10%
    min_delta, max_delta = fpl_results.first
    assert_in_delta -5.0, min_delta, 0.1
    assert_in_delta 10.0, max_delta, 0.1
  end

  def test_fpl_analysis_basic
    analysis = SQA::FPOP.fpl_analysis(@simple_prices, fpop: 3)

    assert_instance_of Array, analysis
    assert analysis.first.is_a?(Hash)
    assert analysis.first.key?(:min_delta)
    assert analysis.first.key?(:max_delta)
    assert analysis.first.key?(:risk)
    assert analysis.first.key?(:direction)
    assert analysis.first.key?(:magnitude)
    assert analysis.first.key?(:interpretation)
  end

  def test_determine_direction_up
    direction = SQA::FPOP.determine_direction(5.0, 10.0)
    assert_equal :UP, direction
  end

  def test_determine_direction_down
    direction = SQA::FPOP.determine_direction(-10.0, -5.0)
    assert_equal :DOWN, direction
  end

  def test_determine_direction_uncertain
    direction = SQA::FPOP.determine_direction(-5.0, 10.0)
    assert_equal :UNCERTAIN, direction
  end

  def test_determine_direction_flat
    direction = SQA::FPOP.determine_direction(0.0, 0.0)
    assert_equal :FLAT, direction
  end

  def test_calculate_magnitude
    magnitude = SQA::FPOP.calculate_magnitude(-5.0, 15.0)
    assert_in_delta 5.0, magnitude, 0.01
  end

  def test_build_interpretation
    interp = SQA::FPOP.build_interpretation(-5.0, 15.0)
    assert_match /UNCERTAIN/, interp
    assert_match /5\.0%/, interp  # magnitude
    assert_match /10\.0% risk/, interp  # ±(risk/2)
  end

  def test_filter_by_quality_min_magnitude
    analysis = SQA::FPOP.fpl_analysis(@simple_prices, fpop: 3)
    indices = SQA::FPOP.filter_by_quality(analysis, min_magnitude: 7.0)

    assert indices.is_a?(Array)
    # All filtered points should have magnitude >= 7.0
    indices.each do |idx|
      assert analysis[idx][:magnitude] >= 7.0
    end
  end

  def test_filter_by_quality_max_risk
    analysis = SQA::FPOP.fpl_analysis(@volatile_prices, fpop: 2)
    indices = SQA::FPOP.filter_by_quality(analysis, max_risk: 10.0)

    # All filtered points should have risk <= 10.0
    indices.each do |idx|
      assert analysis[idx][:risk] <= 10.0
    end
  end

  def test_filter_by_quality_directions
    analysis = SQA::FPOP.fpl_analysis([100, 105, 110, 115, 120], fpop: 2)
    indices = SQA::FPOP.filter_by_quality(analysis, directions: [:UP])

    # All filtered points should be :UP
    indices.each do |idx|
      assert_equal :UP, analysis[idx][:direction]
    end
  end

  def test_risk_reward_ratios
    analysis = SQA::FPOP.fpl_analysis(@simple_prices, fpop: 3)
    ratios = SQA::FPOP.risk_reward_ratios(analysis)

    assert_instance_of Array, ratios
    assert_equal analysis.size, ratios.size
    ratios.each do |ratio|
      assert ratio.is_a?(Numeric)
      assert ratio >= 0
    end
  end

  def test_fpl_validation_empty_array
    assert_raises(ArgumentError) do
      SQA::FPOP.fpl([], fpop: 10)
    end
  end

  def test_fpl_validation_not_array
    assert_raises(ArgumentError) do
      SQA::FPOP.fpl("not an array", fpop: 10)
    end
  end

  def test_fpl_validation_negative_fpop
    assert_raises(ArgumentError) do
      SQA::FPOP.fpl(@simple_prices, fpop: -5)
    end
  end

  def test_fpl_validation_zero_prices
    assert_raises(ArgumentError) do
      SQA::FPOP.fpl([100, 0, 110], fpop: 2)
    end
  end

  def test_fpl_validation_negative_prices
    assert_raises(ArgumentError) do
      SQA::FPOP.fpl([100, -50, 110], fpop: 2)
    end
  end
end
