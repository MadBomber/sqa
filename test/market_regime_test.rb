# test/market_regime_test.rb
# frozen_string_literal: true

require_relative 'test_helper'

class MarketRegimeTest < Minitest::Test
  def setup
    # Create test price data
    @bull_prices = (1..100).map { |i| 100 + i * 0.5 }  # Uptrend
    @bear_prices = (1..100).map { |i| 100 - i * 0.5 }  # Downtrend
    @sideways_prices = (1..100).map { |i| 100 + Math.sin(i * 0.1) * 2 }  # Oscillating
    @volatile_prices = (1..100).map { |i| 100 + rand(-10..10) }  # High volatility
  end

  def test_detect_trend_bull
    trend = SQA::MarketRegime.detect_trend(@bull_prices)
    assert_equal :bull, trend
  end

  def test_detect_trend_bear
    trend = SQA::MarketRegime.detect_trend(@bear_prices)
    assert_equal :bear, trend
  end

  def test_detect_trend_sideways
    trend = SQA::MarketRegime.detect_trend(@sideways_prices)
    assert_equal :sideways, trend
  end

  def test_detect_trend_unknown_short_array
    trend = SQA::MarketRegime.detect_trend([100, 105])
    assert_equal :unknown, trend
  end

  def test_detect_volatility_low
    low_vol_prices = (1..100).map { |i| 100 + i * 0.1 }  # Gentle trend
    volatility = SQA::MarketRegime.detect_volatility(low_vol_prices)
    assert_equal :low, volatility
  end

  def test_detect_volatility_high
    volatility = SQA::MarketRegime.detect_volatility(@volatile_prices)
    assert_includes [:medium, :high], volatility
  end

  def test_detect_volatility_unknown_short_array
    volatility = SQA::MarketRegime.detect_volatility([100, 105])
    assert_equal :unknown, volatility
  end

  def test_detect_strength_strong
    strong_trend = (1..100).map { |i| 100 + i }  # Consistent up
    strength = SQA::MarketRegime.detect_strength(strong_trend)
    assert_equal :strong, strength
  end

  def test_detect_strength_weak
    strength = SQA::MarketRegime.detect_strength(@sideways_prices)
    assert_equal :weak, strength
  end

  def test_detect_strength_unknown_short_array
    strength = SQA::MarketRegime.detect_strength([100, 105])
    assert_equal :unknown, strength
  end

  def test_detect_basic
    skip "Requires stock object" unless ENV['RUN_INTEGRATION_TESTS']

    stock = create_mock_stock(@bull_prices)
    regime = SQA::MarketRegime.detect(stock)

    assert regime.is_a?(Hash)
    assert_includes [:bull, :bear, :sideways, :unknown], regime[:type]
    assert_includes [:low, :medium, :high, :unknown], regime[:volatility]
    assert_includes [:weak, :moderate, :strong, :unknown], regime[:strength]
    assert_equal 60, regime[:lookback_days]
    assert_instance_of Time, regime[:detected_at]
  end

  def test_detect_history
    skip "Requires stock object" unless ENV['RUN_INTEGRATION_TESTS']

    # Create alternating bull/bear prices
    alternating = []
    5.times do
      50.times { |i| alternating << 100 + i }  # Bull
      50.times { |i| alternating << 150 - i }  # Bear
    end

    stock = create_mock_stock(alternating)
    regimes = SQA::MarketRegime.detect_history(stock, window: 30)

    assert regimes.is_a?(Array)
    assert regimes.size > 1, "Should detect multiple regime changes"

    regimes.each do |regime|
      assert_includes [:bull, :bear, :sideways], regime[:type]
      assert regime[:start_index] < regime[:end_index]
      assert_equal regime[:end_index] - regime[:start_index], regime[:duration]
    end
  end

  def test_split_by_regime
    skip "Requires stock object" unless ENV['RUN_INTEGRATION_TESTS']

    alternating = []
    50.times { |i| alternating << 100 + i }  # Bull
    50.times { |i| alternating << 150 - i }  # Bear

    stock = create_mock_stock(alternating)
    splits = SQA::MarketRegime.split_by_regime(stock)

    assert splits.is_a?(Hash)
    assert_includes splits.keys, :bull
    assert_includes splits.keys, :bear
    assert_includes splits.keys, :sideways

    splits.each do |regime, periods|
      assert periods.is_a?(Array)
      periods.each do |period|
        assert period.key?(:prices)
        assert period.key?(:start_index)
        assert period.key?(:end_index)
        assert period.key?(:duration)
      end
    end
  end

  private

  def create_mock_stock(prices)
    dates = prices.size.times.map { |i| (Date.today - prices.size + i).to_s }

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
