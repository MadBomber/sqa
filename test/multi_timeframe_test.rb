# test/multi_timeframe_test.rb
# frozen_string_literal: true

require_relative 'test_helper'

class MultiTimeframeTest < Minitest::Test
  def setup
    skip "Skipping integration test - set RUN_INTEGRATION_TESTS=1 to run" unless ENV['RUN_INTEGRATION_TESTS']

    @stock = SQA::Stock.new(ticker: 'AAPL')
    @mta = SQA::MultiTimeframe.new(stock: @stock)
  end

  def test_initialization
    assert_instance_of SQA::MultiTimeframe, @mta
    assert @mta.timeframes.key?(:daily)
    assert @mta.timeframes.key?(:weekly)
    assert @mta.timeframes.key?(:monthly)
  end

  def test_trend_alignment
    alignment = @mta.trend_alignment(lookback: 20)

    assert_instance_of Hash, alignment
    assert alignment.key?(:daily)
    assert alignment.key?(:weekly)
    assert alignment.key?(:monthly)
    assert alignment.key?(:aligned)
    assert alignment.key?(:direction)

    %i[up down sideways].each do |timeframe|
      assert %i[up down sideways].include?(alignment[timeframe]) if alignment.key?(timeframe)
    end

    assert [true, false].include?(alignment[:aligned])
    assert %i[bullish bearish mixed].include?(alignment[:direction])
  end

  def test_signal_generation
    signal = @mta.signal(
      strategy_class: SQA::Strategy::RSI,
      higher_timeframe: :weekly,
      lower_timeframe: :daily
    )

    assert %i[buy sell hold].include?(signal)
  end

  def test_support_resistance
    levels = @mta.support_resistance(tolerance: 0.02)

    assert_instance_of Hash, levels
    assert levels.key?(:support)
    assert levels.key?(:resistance)
    assert levels.key?(:current_price)

    assert_instance_of Array, levels[:support]
    assert_instance_of Array, levels[:resistance]
  end

  def test_indicators_across_timeframes
    results = @mta.indicators(indicator: :rsi, period: 14)

    assert_instance_of Hash, results
    assert results.key?(:daily)
    assert results.key?(:weekly)
    assert results.key?(:monthly)

    results.each_value do |values|
      assert_instance_of Array, values
    end
  end

  def test_detect_divergence
    divergences = @mta.detect_divergence

    assert_instance_of Hash, divergences

    divergences.each_value do |divergence|
      assert %i[bearish_divergence bullish_divergence no_divergence].include?(divergence)
    end
  end

  def test_confirmation
    confirmation = @mta.confirmation(strategy_class: SQA::Strategy::RSI)

    assert_instance_of Hash, confirmation
    assert confirmation.key?(:signals)
    assert confirmation.key?(:confirmed)
    assert confirmation.key?(:consensus)

    assert_instance_of Hash, confirmation[:signals]
    assert [true, false].include?(confirmation[:confirmed])
    assert %i[buy sell hold].include?(confirmation[:consensus])
  end
end

# Runs without network: a synthetic daily series too short for 14-period
# indicators on the monthly timeframe.
class MultiTimeframeShortDataTest < Minitest::Test
  def setup
    n = 100
    prices = Array.new(n) { |i| 100 + (Math.sin(i / 7.0) * 8) + (i * 0.05) }
    df = SQA::DataFrame.new({ "adj_close_price" => prices, "volume" => Array.new(n, 1_000.0) })
    @mta = SQA::MultiTimeframe.new(stock: Struct.new(:df).new(df))
  end

  def test_detect_divergence_skips_short_timeframes
    divergences = @mta.detect_divergence

    assert divergences.key?(:daily)
    refute divergences.key?(:monthly)
  end

  def test_confirmation_with_short_timeframes
    result = @mta.confirmation(strategy_class: SQA::Strategy::RSI)

    assert_includes %i[buy sell hold], result[:consensus]
    assert_equal %i[daily weekly monthly], result[:signals].keys
  end

  def test_indicators_skip_short_timeframes
    results = @mta.indicators(indicator: :rsi, period: 14)

    assert results.key?(:daily)
    refute results.key?(:monthly)
  end

  def test_signal_with_fewer_than_ten_higher_bars
    signal = @mta.signal(strategy_class: SQA::Strategy::RSI, higher_timeframe: :monthly)

    assert_includes %i[buy sell hold], signal
  end
end
