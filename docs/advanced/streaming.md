# Real-Time Streaming

## Overview

Process live price data with event callbacks and parallel strategy execution for real-time trading signals.

## Quick Start

```ruby
require 'sqa'

# Create stream
stream = SQA::Stream.new(
  ticker: 'AAPL',
  strategies: [SQA::Strategy::RSI, SQA::Strategy::MACD],
  window_size: 50
)

# Register callback
stream.on_signal do |signal, data|
  puts "#{Time.now}: Signal = #{signal}"
  puts "Price: #{data[:price]}"
  puts "Volume: #{data[:volume]}"
  
  # Execute trade, send alert, log data, etc.
  execute_trade(signal, data) if signal != :hold
end

# Start receiving updates
stream.update(price: 150.25, volume: 1_000_000)
stream.update(price: 150.50, volume: 1_200_000)
```

## Features

### Rolling Window
Maintains recent price/volume history:

```ruby
stream = SQA::Stream.new(
  ticker: 'AAPL',
  window_size: 50  # Keep last 50 data points
)

# Automatically manages memory
1000.times do |i|
  stream.update(price: 100 + rand, volume: 1000000)
  # Only keeps most recent 50 points
end
```

### On-the-Fly Indicators
Calculates indicators from rolling window:

```ruby
stream.update(price: 150.0, volume: 1_000_000)

# Indicators calculated automatically
# - RSI from last 14 prices
# - MACD from price history
# - SMA/EMA from rolling window
```

### Parallel Strategy Execution
Runs multiple strategies simultaneously:

```ruby
stream = SQA::Stream.new(
  ticker: 'AAPL',
  strategies: [
    SQA::Strategy::RSI,
    SQA::Strategy::MACD,
    SQA::Strategy::BollingerBands
  ]
)

# All strategies execute on each update
stream.update(price: 150.0, volume: 1_000_000)
# Each strategy generates independent signal
```

### Signal Aggregation
Combine multiple strategy signals:

```ruby
stream.on_signal do |signals, data|
  # signals = {
  #   RSI: :buy,
  #   MACD: :hold,
  #   BollingerBands: :buy
  # }
  
  # Count votes
  buy_votes = signals.values.count(:buy)
  sell_votes = signals.values.count(:sell)
  
  # Consensus decision
  if buy_votes >= 2
    execute_buy(data[:price])
  elsif sell_votes >= 2
    execute_sell(data[:price])
  end
end
```

## Complete Example

```ruby
# Initialize stream
stream = SQA::Stream.new(
  ticker: 'AAPL',
  strategies: [
    SQA::Strategy::RSI,
    SQA::Strategy::MACD
  ],
  window_size: 100
)

# Track performance
trades = []

# Register callbacks
stream.on_signal do |signals, data|
  consensus = calculate_consensus(signals)
  
  if consensus == :buy
    trades << {
      action: :buy,
      price: data[:price],
      time: Time.now
    }
    send_alert("BUY signal at $#{data[:price]}")
  elsif consensus == :sell
    trades << {
      action: :sell,
      price: data[:price],
      time: Time.now
    }
    send_alert("SELL signal at $#{data[:price]}")
  end
end

# Simulate live data feed
loop do
  # Get current price from API/feed
  current_data = fetch_live_data('AAPL')
  
  stream.update(
    price: current_data[:price],
    volume: current_data[:volume]
  )
  
  sleep 60  # Update every minute
end
```

## Integration Examples

### With WebSocket Feed

```ruby
require 'faye/websocket'
require 'eventmachine'

EM.run do
  ws = Faye::WebSocket::Client.new('wss://stream.example.com')
  
  ws.on :message do |event|
    data = JSON.parse(event.data)
    stream.update(
      price: data['price'],
      volume: data['volume']
    )
  end
end
```

### With REST API Polling

```ruby
require 'faraday'

loop do
  response = Faraday.get("https://api.example.com/quote/AAPL")
  data = JSON.parse(response.body)
  
  stream.update(
    price: data['lastPrice'],
    volume: data['volume']
  )
  
  sleep 10
end
```

## Best Practices

1. **Error Handling**: Wrap callbacks in begin/rescue
2. **Performance**: Limit callback complexity
3. **Memory**: Use appropriate window_size
4. **Validation**: Verify data before processing
5. **Logging**: Track all signals and actions

## Related

- [Portfolio Management](portfolio.md) - Execute trades from signals
- [Backtesting](backtesting.md) - Test strategies before going live
- [Risk Management](risk-management.md) - Position sizing for live trading

