# Bollinger Bands Strategy

## Overview

The Bollinger Bands strategy uses volatility bands to identify oversold and overbought conditions. The strategy generates buy signals when price touches the lower band and sell signals when price touches the upper band.

## How It Works

Bollinger Bands consist of three lines:

- **Middle Band**: 20-period Simple Moving Average (SMA)
- **Upper Band**: Middle Band + (2 × Standard Deviation)
- **Lower Band**: Middle Band - (2 × Standard Deviation)

The bands expand and contract based on market volatility. When volatility increases, the bands widen; when volatility decreases, the bands narrow.

## Trading Signals

### Buy Signal
Price touches or falls below the **lower band**, indicating an oversold condition.

```ruby
current_price <= lower_band  # => :buy
```

### Sell Signal
Price touches or exceeds the **upper band**, indicating an overbought condition.

```ruby
current_price >= upper_band  # => :sell
```

### Hold Signal
Price remains between the bands.

```ruby
lower_band < current_price < upper_band  # => :hold
```

## Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| Period | 20 | Number of periods for SMA calculation |
| Std Dev | 2.0 | Number of standard deviations for bands |

## Usage Example

```ruby
require 'sqa'
require 'ostruct'

# Load stock data
stock = SQA::Stock.new(ticker: 'AAPL')
prices = stock.df["adj_close_price"].to_a

# Create vector with price data
vector = OpenStruct.new(prices: prices)

# Execute strategy
signal = SQA::Strategy::BollingerBands.trade(vector)
puts "Signal: #{signal}"  # => :buy, :sell, or :hold
```

## Backtesting Example

```ruby
# Create backtest with Bollinger Bands strategy
backtest = SQA::Backtest.new(
  stock: stock,
  strategy: SQA::Strategy::BollingerBands,
  initial_cash: 10_000
)

results = backtest.run

puts "Total Return: #{results.total_return}%"
puts "Sharpe Ratio: #{results.sharpe_ratio}"
puts "Max Drawdown: #{results.max_drawdown}%"
puts "Win Rate: #{results.win_rate}%"
```

## Characteristics

| Attribute | Value |
|-----------|-------|
| Complexity | Medium |
| Best Market | Volatile, range-bound markets |
| Typical Win Rate | 50-60% |
| Risk Level | Medium |
| Time Horizon | Short to medium term |

## Strengths

- ✅ Works well in ranging markets
- ✅ Adapts to volatility changes
- ✅ Provides clear entry/exit points
- ✅ Simple to understand and implement

## Weaknesses

- ❌ Less effective in strong trends
- ❌ Can generate false signals during breakouts
- ❌ Requires sufficient price history (20+ periods)
- ❌ May whipsaw in choppy markets

## Tips for Best Results

1. **Combine with Trend Indicators**: Use with RSI or MACD to filter false signals
2. **Watch for Band Squeezes**: Narrow bands often precede big moves
3. **Adjust Parameters**: Consider wider bands (3 std dev) for less frequent signals
4. **Volume Confirmation**: Look for high volume on band touches for stronger signals
5. **Avoid in Trends**: Strategy works best in sideways markets

## Implementation Details

The strategy is implemented in `lib/sqa/strategy/bollinger_bands.rb` and uses TA-Lib's `bbands` indicator via the `sqa-tai` gem:

```ruby
class SQA::Strategy::BollingerBands
  def self.trade(vector)
    # Calculate Bollinger Bands
    upper, middle, lower = SQAI.bbands(
      prices,
      period: 20,
      nbdev_up: 2.0,
      nbdev_down: 2.0
    )

    # Compare current price to bands
    # ... (see source for full implementation)
  end
end
```

## Related Strategies

- [RSI Strategy](rsi.md) - Combine for better oversold/overbought detection
- [Volume Breakout](volume-breakout.md) - Use together to confirm breakouts
- [Mean Reversion](mean-reversion.md) - Similar range-trading approach

## Further Reading

- [Bollinger Bands on Wikipedia](https://en.wikipedia.org/wiki/Bollinger_Bands)
- [John Bollinger's Official Site](https://www.bollingerbands.com/)
- [Understanding Volatility with Bollinger Bands](../concepts/volatility.md)
