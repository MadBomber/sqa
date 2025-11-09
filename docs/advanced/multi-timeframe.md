# Multi-Timeframe Analysis

Analyze multiple timeframes simultaneously for better trade timing.

## Setup

```ruby
mta = SQA::MultiTimeframe.new(stock: stock)
```

## Trend Alignment

```ruby
alignment = mta.trend_alignment

# {
#   daily: :up,
#   weekly: :up,
#   monthly: :up,
#   aligned: true,
#   direction: :bullish
# }

if alignment[:aligned] && alignment[:direction] == :bullish
  puts "Strong uptrend across all timeframes"
end
```

## Multi-Timeframe Signal

```ruby
# Higher timeframe = trend, lower timeframe = timing
signal = mta.signal(
  strategy_class: SQA::Strategy::RSI,
  higher_timeframe: :weekly,   # Trend filter
  lower_timeframe: :daily      # Entry timing
)

# Only takes trades aligned with higher timeframe trend
```

## Support/Resistance

```ruby
# Find levels that appear across multiple timeframes
levels = mta.support_resistance(tolerance: 0.02)

levels.each do |level|
  puts "Strong level at #{level[:price]}"
  puts "  Appears in: #{level[:timeframes].join(', ')}"
end
```

## Divergence Detection

```ruby
# Price makes new high but indicator doesn't (bearish)
divergence = mta.detect_divergence(
  indicator: :rsi,
  lookback: 20
)

if divergence[:type] == :bearish
  puts "Bearish divergence detected - potential reversal"
end
```

