# Trading Strategies

Explore SQA's comprehensive suite of trading strategies.

## Overview

SQA provides 13+ built-in trading strategies, from simple moving average crossovers to advanced rule-based systems. All strategies follow a common interface and can be easily backtested or combined.

## Strategy Categories

### Trend-Following Strategies
Strategies that identify and follow market trends:

- **SMA Strategy** - Simple Moving Average crossovers
- **EMA Strategy** - Exponential Moving Average crossovers
- **MACD Strategy** - Moving Average Convergence Divergence

### Momentum Strategies
Strategies based on price momentum and oscillators:

- **RSI Strategy** - Relative Strength Index (oversold/overbought)
- **Stochastic Strategy** - Stochastic oscillator crossovers

### Volatility Strategies
Strategies that use volatility measures:

- **Bollinger Bands Strategy** - Price touches bands
- **ATR-based Strategies** - Average True Range volatility

### Volume Strategies
Strategies incorporating volume analysis:

- **Volume Breakout** - High volume price breakouts

### Mean Reversion
Strategies assuming prices return to average:

- **Mean Reversion Strategy** - Statistical mean reversion

### Advanced Strategies
Complex, rule-based approaches:

- **KBS Strategy** - Knowledge-Based System with RETE engine
- **Consensus Strategy** - Aggregates multiple strategies

## Using Strategies

### Basic Usage

```ruby
require 'sqa'
require 'ostruct'

# Create data vector
vector = OpenStruct.new(
  rsi: { trend: :over_sold },
  prices: [100, 102, 105, 103, 107]
)

# Execute strategy
signal = SQA::Strategy::RSI.trade(vector)
# => :buy, :sell, or :hold
```

### Backtesting

```ruby
backtest = SQA::Backtest.new(
  stock: stock,
  strategy: SQA::Strategy::MACD,
  initial_cash: 10_000
)

results = backtest.run
puts "Return: #{results.total_return}%"
```

## Strategy Comparison

| Strategy | Complexity | Best For | Typical Win Rate |
|----------|------------|----------|------------------|
| SMA | Low | Trending markets | 45-55% |
| RSI | Low | Range-bound markets | 50-60% |
| MACD | Medium | Trending markets | 45-55% |
| Bollinger Bands | Medium | Volatile markets | 50-60% |
| KBS | High | Complex rules | Varies |

## Next Steps

- [Built-in Strategies](bollinger-bands.md) - Explore each strategy in detail
- [Custom Strategies](custom.md) - Create your own strategies
- [Backtesting](../advanced/backtesting.md) - Test strategies historically
