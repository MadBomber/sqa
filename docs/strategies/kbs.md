# KBS (Knowledge-Based Strategy)

## Overview

Advanced rule-based trading system using RETE forward-chaining inference engine. Combines multiple indicators with custom logic rules using the `kbs` (knowledge-based system) ruby gem.  A complete [documentation website for the `kbs` ruby gem is available.](https://madbomber.github.io/kbs)

## How It Works

Defines trading rules with conditions and actions:
- **Conditions** (`on`): Facts that must be true
- **Actions** (`perform`): What to do when conditions met

## Rule Definition

```ruby
strategy = SQA::Strategy::KBS.new(load_defaults: true)
kb = strategy.kb

# Add custom rule
strategy.add_rule :buy_oversold_uptrend do
  on :rsi, { level: :oversold }
  on :trend, { short_term: :up }
  perform do
    kb.assert(:signal, { action: :buy, confidence: :high })
  end
end
```

## Default Rules

The KBS strategy includes 10 default rules:

1. Buy on RSI oversold in uptrend
2. Sell on RSI overbought in downtrend
3. Buy on bullish MACD crossover
4. Sell on bearish MACD crossover
5. Buy at lower Bollinger Band
6. Sell at upper Bollinger Band
7. Buy on stochastic oversold crossover
8. Sell on stochastic overbought crossover
9. Buy on SMA golden cross
10. Sell on SMA death cross

## Usage Example

```ruby
# Use with default rules
strategy = SQA::Strategy::KBS.new(load_defaults: true)

# Provide market data
prices = stock.df["adj_close_price"].to_a
vector = OpenStruct.new(
  rsi: SQAI.rsi(prices, period: 14),
  prices: prices
)

signal = strategy.execute(vector)
```

## Advanced Example

```ruby
# Create custom strategy without defaults
strategy = SQA::Strategy::KBS.new(load_defaults: false)
kb = strategy.kb

# Define sophisticated multi-condition rule
strategy.add_rule :strong_buy do
  on :rsi, { level: :oversold }
  on :macd, { crossover: :bullish }
  on :volume, { level: :high }
  without :position  # Don't buy if already holding

  perform do
    kb.assert(:signal, {
      action: :buy,
      confidence: :high,
      reason: :triple_confirmation
    })
  end
end

# Execute
signal = strategy.execute(vector)
```

## Confidence Levels

Signals include confidence scoring:
- **High**: 1.0
- **Medium**: 0.6
- **Low**: 0.3

Multiple rules can fire, with aggregate confidence determining final signal.

## Characteristics

- **Complexity**: High
- **Best Market**: All markets (depends on rules)
- **Win Rate**: Varies (50-70% with good rules)

## Strengths

- ✅ Highly customizable
- ✅ Combines multiple indicators
- ✅ Confidence scoring
- ✅ Forward-chaining inference
- ✅ Can encode expert knowledge

## Weaknesses

- ❌ Complex to configure
- ❌ Requires domain knowledge
- ❌ Can be slow with many rules
- ❌ Overfitting risk

## Tips

1. **Start Simple**: Begin with 2-3 rules
2. **Test Thoroughly**: Backtest each rule independently
3. **Avoid Conflicts**: Ensure rules don't contradict
4. **Use Confidence**: Combine weak signals for stronger conviction
5. **Monitor Performance**: Track which rules fire most often

## Available Facts

The KBS strategy processes these fact types:

- `:rsi` - RSI indicator data
- `:macd` - MACD crossovers
- `:trend` - Price trend analysis
- `:bollinger` - Bollinger Band position
- `:stochastic` - Stochastic oscillator
- `:volume` - Volume analysis
- `:sma_crossover` - SMA crossovers

## DSL Keywords

- `on` - Assert condition (fact must exist with attributes)
- `without` - Negated condition (fact must NOT exist)
- `perform` - Action to execute when rule fires

## Important Note

Due to KBS gem DSL limitations, you must use `kb.assert` (not just `assert`) inside `perform` blocks:

```ruby
# CORRECT
kb = strategy.kb
strategy.add_rule :my_rule do
  on :condition
  perform { kb.assert(:signal, { action: :buy }) }
end

# INCORRECT
strategy.add_rule :my_rule do
  on :condition
  perform { assert(:signal, { action: :buy }) }  # Won't work!
end
```

## Related

- [Strategy Generator](../advanced/strategy-generator.md) - Auto-generate rules
- [Genetic Programming](../genetic_programming.md) - Optimize rule parameters
