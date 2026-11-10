require_relative 'test_helper'

class StreamTest < Minitest::Test
  def setup
    @stream = SQA::Stream.new(ticker: 'AAPL', window_size: 50)
  end

  def test_initialization
    assert_equal 'AAPL', @stream.ticker
    assert_equal 50, @stream.window_size
    assert_empty @stream.strategies
  end

  def test_add_strategy
    @stream.add_strategy(SQA::Strategy::RSI)

    assert_equal 1, @stream.strategies.size
    assert_equal SQA::Strategy::RSI, @stream.strategies.first
  end

  def test_update_adds_to_buffer
    @stream.update(price: 150.0, volume: 1_000_000)

    assert_equal 1, @stream.data_buffer[:prices].size
    assert_equal 150.0, @stream.data_buffer[:prices].first
  end

  def test_current_price
    @stream.update(price: 150.0)
    @stream.update(price: 151.0)

    assert_equal 151.0, @stream.current_price
  end

  def test_recent_prices
    @stream.update(price: 150.0)
    @stream.update(price: 151.0)
    @stream.update(price: 152.0)

    prices = @stream.recent_prices
    assert_equal 3, prices.size
    assert_equal [150.0, 151.0, 152.0], prices
  end

  def test_recent_prices_with_count
    5.times { |i| @stream.update(price: 150.0 + i) }

    recent = @stream.recent_prices(3)
    assert_equal 3, recent.size
    assert_equal [152.0, 153.0, 154.0], recent
  end

  def test_window_size_trimming
    # Add more than window size
    60.times { |i| @stream.update(price: 100.0 + i) }

    # Should only keep window_size (50) elements
    assert_equal 50, @stream.data_buffer[:prices].size
  end

  def test_on_update_callback
    callback_called = false
    callback_data = nil

    @stream.on_update do |data|
      callback_called = true
      callback_data = data
    end

    @stream.update(price: 150.0, volume: 1_000_000)

    assert callback_called
    assert_equal 150.0, callback_data[:price]
    assert_equal 1_000_000, callback_data[:volume]
  end

  def test_on_signal_callback
    signal_called = false
    received_signal = nil
    received_data = nil

    @stream.on_signal do |signal, data|
      signal_called = true
      received_signal = signal
      received_data = data
    end

    # A strategy that always votes :buy drives the consensus away from the
    # initial :hold signal, so the callback fires when the signal changes.
    @stream.add_strategy(->(_v) { :buy })

    # Feed enough data points to exceed the minimum needed to run strategies.
    35.times { |i| @stream.update(price: 100.0 + i) }

    assert signal_called, 'on_signal callback was never invoked'
    assert_equal :buy, received_signal
    assert_equal :buy, received_data[:signal]
  end

  def test_stats
    @stream.update(price: 150.0)
    @stream.update(price: 151.0)

    stats = @stream.stats

    assert_equal 'AAPL', stats[:ticker]
    assert_equal 2, stats[:updates]
    assert_equal 2, stats[:buffer_size]
    assert_equal 151.0, stats[:current_price]
  end

  def test_reset
    @stream.update(price: 150.0)
    @stream.update(price: 151.0)

    @stream.reset

    assert_equal 0, @stream.data_buffer[:prices].size
    assert_equal 0, @stream.instance_variable_get(:@update_count)
  end

  def test_thread_safety
    # Basic test that operations don't raise errors
    threads = []

    10.times do
      threads << Thread.new do
        @stream.update(price: rand(100.0..200.0))
      end
    end

    threads.each(&:join)

    assert_equal 10, @stream.data_buffer[:prices].size
  end

  def test_indicator_caching
    30.times { |i| @stream.update(price: 100.0 + i) }

    # First call calculates
    rsi1 = @stream.indicator(:rsi, period: 14)

    # Second call should use cache
    rsi2 = @stream.indicator(:rsi, period: 14)

    assert_equal rsi1, rsi2
  end
end
