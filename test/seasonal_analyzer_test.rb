# test/seasonal_analyzer_test.rb
# frozen_string_literal: true

require_relative 'test_helper'

class SeasonalAnalyzerTest < Minitest::Test
  def setup
    # Create seasonal test data - strong Q4 performance
    @seasonal_data = create_seasonal_stock
    @flat_data = create_flat_stock
  end

  def test_analyze_returns_hash
    skip "Requires stock object" unless ENV['RUN_INTEGRATION_TESTS']

    result = SQA::SeasonalAnalyzer.analyze(@seasonal_data)

    assert result.is_a?(Hash)
    assert result.key?(:monthly_returns)
    assert result.key?(:quarterly_returns)
    assert result.key?(:best_months)
    assert result.key?(:worst_months)
    assert result.key?(:best_quarters)
    assert result.key?(:worst_quarters)
    assert result.key?(:has_seasonal_pattern)
  end

  def test_monthly_returns_structure
    skip "Requires stock object" unless ENV['RUN_INTEGRATION_TESTS']

    result = SQA::SeasonalAnalyzer.analyze(@seasonal_data)
    monthly = result[:monthly_returns]

    assert_equal 12, monthly.size

    (1..12).each do |month|
      assert monthly.key?(month)
      assert monthly[month].key?(:avg_return)
      assert monthly[month].key?(:count)
      assert monthly[month].key?(:positive_days)
      assert monthly[month].key?(:negative_days)
    end
  end

  def test_quarterly_returns_structure
    skip "Requires stock object" unless ENV['RUN_INTEGRATION_TESTS']

    result = SQA::SeasonalAnalyzer.analyze(@seasonal_data)
    quarterly = result[:quarterly_returns]

    assert_equal 4, quarterly.size

    (1..4).each do |quarter|
      assert quarterly.key?(quarter)
      assert quarterly[quarter].key?(:avg_return)
      assert quarterly[quarter].key?(:count)
      assert quarterly[quarter].key?(:positive_days)
      assert quarterly[quarter].key?(:negative_days)
    end
  end

  def test_best_worst_months
    skip "Requires stock object" unless ENV['RUN_INTEGRATION_TESTS']

    result = SQA::SeasonalAnalyzer.analyze(@seasonal_data)

    assert_equal 3, result[:best_months].size
    assert_equal 3, result[:worst_months].size

    result[:best_months].each do |month|
      assert month >= 1 && month <= 12
    end

    result[:worst_months].each do |month|
      assert month >= 1 && month <= 12
    end
  end

  def test_best_worst_quarters
    skip "Requires stock object" unless ENV['RUN_INTEGRATION_TESTS']

    result = SQA::SeasonalAnalyzer.analyze(@seasonal_data)

    assert_equal 2, result[:best_quarters].size
    assert_equal 2, result[:worst_quarters].size

    result[:best_quarters].each do |quarter|
      assert quarter >= 1 && quarter <= 4
    end

    result[:worst_quarters].each do |quarter|
      assert quarter >= 1 && quarter <= 4
    end
  end

  def test_detect_seasonality_true
    monthly_returns = {
      1 => { avg_return: 5.0 },
      2 => { avg_return: 1.0 },
      3 => { avg_return: -2.0 },
      4 => { avg_return: 8.0 },
      5 => { avg_return: -3.0 },
      6 => { avg_return: -1.0 },
      7 => { avg_return: 2.0 },
      8 => { avg_return: 0.0 },
      9 => { avg_return: 3.0 },
      10 => { avg_return: 7.0 },
      11 => { avg_return: 6.0 },
      12 => { avg_return: 9.0 }
    }

    result = SQA::SeasonalAnalyzer.detect_seasonality(monthly_returns)
    assert result, "Should detect seasonality with high variance"
  end

  def test_detect_seasonality_false
    # Flat returns - no seasonality
    monthly_returns = {}
    (1..12).each do |m|
      monthly_returns[m] = { avg_return: 1.0 }
    end

    result = SQA::SeasonalAnalyzer.detect_seasonality(monthly_returns)
    refute result, "Should not detect seasonality with flat returns"
  end

  def test_filter_by_months
    skip "Requires stock object" unless ENV['RUN_INTEGRATION_TESTS']

    # Filter for Q4 months (10, 11, 12)
    result = SQA::SeasonalAnalyzer.filter_by_months(@seasonal_data, [10, 11, 12])

    assert result.is_a?(Hash)
    assert result.key?(:indices)
    assert result.key?(:dates)
    assert result.key?(:prices)

    # Check all returned dates are in Q4
    result[:dates].each do |date|
      assert_includes [10, 11, 12], date.month
    end

    # Indices and prices should match in size
    assert_equal result[:indices].size, result[:dates].size
    assert_equal result[:indices].size, result[:prices].size
  end

  def test_filter_by_quarters
    skip "Requires stock object" unless ENV['RUN_INTEGRATION_TESTS']

    # Filter for Q1 and Q4
    result = SQA::SeasonalAnalyzer.filter_by_quarters(@seasonal_data, [1, 4])

    assert result.is_a?(Hash)
    assert result.key?(:indices)
    assert result.key?(:dates)
    assert result.key?(:prices)

    # Check all returned dates are in Q1 or Q4
    result[:dates].each do |date|
      quarter = ((date.month - 1) / 3) + 1
      assert_includes [1, 4], quarter
    end
  end

  def test_context_for_date
    test_date = Date.new(2024, 12, 15)
    context = SQA::SeasonalAnalyzer.context_for_date(test_date)

    assert_equal 12, context[:month]
    assert_equal 4, context[:quarter]
    assert_equal "December", context[:month_name]
    assert_equal "Q4", context[:quarter_name]
    assert context[:is_year_end]
    refute context[:is_year_start]
    assert context[:is_holiday_season]
    refute context[:is_earnings_season]
  end

  def test_context_for_january
    test_date = Date.new(2024, 1, 15)
    context = SQA::SeasonalAnalyzer.context_for_date(test_date)

    assert_equal 1, context[:month]
    assert_equal 1, context[:quarter]
    assert context[:is_year_start]
    refute context[:is_year_end]
    assert context[:is_earnings_season]
  end

  private

  def create_seasonal_stock
    # Create 2 years of data with strong Q4 performance
    prices = []
    dates = []
    start_date = Date.today - 730

    730.times do |i|
      date = start_date + i
      base_price = 100

      # Add seasonal boost for Q4 (Oct, Nov, Dec)
      if [10, 11, 12].include?(date.month)
        base_price += 10
      end

      # Add random noise
      prices << base_price + rand(-2..2)
      dates << date.to_s
    end

    create_mock_stock(dates, prices)
  end

  def create_flat_stock
    # Create 2 years of flat data
    prices = []
    dates = []
    start_date = Date.today - 730

    730.times do |i|
      date = start_date + i
      prices << 100 + rand(-1..1)
      dates << date.to_s
    end

    create_mock_stock(dates, prices)
  end

  def create_mock_stock(dates, prices)
    df_data = {
      'date' => dates,
      'adj_close_price' => prices
    }

    stock = Object.new
    stock.instance_variable_set(:@df, SQA::DataFrame.new(df_data))

    def stock.df
      @df
    end

    stock
  end
end
