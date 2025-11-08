# SQA Examples

This directory contains comprehensive examples demonstrating advanced features of the SQA (Simple Qualitative Analysis) library.

## Available Examples

### 1. Strategy Generator (`strategy_generator_example.rb`)

**Reverse engineer profitable trades to discover indicator patterns**

This example demonstrates how to mine historical data for profitable entry points and discover which indicator combinations were active at those times. The strategy generator:

- Scans historical data for trades that yielded ≥X% gain
- Identifies which indicators were "active" (e.g., RSI oversold, MACD bullish crossover)
- Discovers common patterns across profitable trades
- Generates trading strategies from discovered patterns
- Backtests generated strategies against traditional strategies

**Run it:**
```bash
./examples/strategy_generator_example.rb
```

**Key Examples:**
- Example 1: Basic pattern discovery for 10% gains
- Example 2: Generate strategies from top patterns
- Example 3: Compare different gain thresholds (5%, 10%, 15%, 20%)
- Example 4: Short-term vs long-term patterns
- Example 5: Export patterns to CSV
- Example 6: Performance comparison of discovered vs traditional strategies
- Example 7: Aggressive pattern mining for 20%+ gains

**Output:**
- Discovered patterns with frequency, average gain, and conditions
- Generated strategy performance metrics
- CSV export of patterns
- Comparison table of strategy performance

---

### 2. Genetic Programming (`genetic_programming_example.rb`)

**Evolve optimal trading strategy parameters through natural selection**

This example shows how to use genetic algorithms to automatically find the best parameters for trading strategies. The genetic program:

- Defines parameter space (e.g., RSI period 7-30, thresholds 20-80)
- Creates random population of strategies
- Evaluates fitness through backtesting
- Evolves through selection, crossover, and mutation
- Tracks evolution history and best individuals

**Run it:**
```bash
./examples/genetic_programming_example.rb
```

**What it demonstrates:**
- Evolving RSI strategy parameters (period, buy/sell thresholds)
- Tournament selection for parent choosing
- Crossover and mutation operations
- Fitness evaluation via backtesting
- Evolution history tracking

**Output:**
- Generation-by-generation evolution progress
- Best parameters found
- Fitness scores (total return %)
- Evolution history chart

---

### 3. Knowledge-Based Strategy (`kbs_strategy_example.rb`)

**Build sophisticated rule-based trading systems with RETE forward chaining**

This example demonstrates the knowledge-based strategy system using RETE pattern matching for complex trading rules:

- Define trading rules with multiple conditions
- Forward-chaining inference engine
- Pattern matching on market conditions
- Confidence-based signal aggregation
- Custom rule creation via DSL

**Run it:**
```bash
./examples/kbs_strategy_example.rb
```

**Key Examples:**
- Example 1: Using default rules (10 built-in patterns)
- Example 2: Creating custom rules
- Example 3: Backtesting KBS strategy
- Example 4: Interactive rule builder with complex conditions

**Output:**
- Trading signals with reasoning
- Working memory facts
- Rule firing explanations
- Backtest performance metrics

---

### 4. Real-Time Streaming (`realtime_stream_example.rb`)

**Process live stock price updates and generate on-the-fly trading signals**

This example shows how to build real-time trading signal systems:

- Event-driven architecture for live data
- Rolling window of recent prices
- On-demand indicator calculation
- Multi-strategy consensus signals
- WebSocket integration patterns

**Run it:**
```bash
./examples/realtime_stream_example.rb
```

**Key Examples:**
- Example 1: Basic streaming setup with callbacks
- Example 2: Multi-strategy consensus
- Example 3: Accessing real-time indicators
- Example 4: Production WebSocket pattern

**Output:**
- Real-time signal notifications
- Price update monitoring
- Indicator calculations on-the-fly
- Production-ready patterns

---

## Running All Examples

To run all examples in sequence:

```bash
for example in examples/*.rb; do
  echo "Running $example..."
  ruby "$example"
  echo ""
done
```

## Integration Examples

### Combining Strategy Generator + Genetic Programming

```ruby
# Discover patterns from history
generator = SQA::StrategyGenerator.new(stock: stock, min_gain_percent: 10.0)
patterns = generator.discover_patterns

# Use GP to optimize the top pattern's parameters
top_pattern = patterns.first
gp = SQA::GeneticProgram.new(stock: stock)
gp.define_genes(
  rsi_period: (10..20).to_a,
  # ... based on pattern conditions
)
best = gp.evolve
```

### Combining KBS + Stream

```ruby
# Create KBS strategy
kbs = SQA::Strategy::KBS.new

# Add to real-time stream
stream = SQA::Stream.new(ticker: 'AAPL', strategies: [kbs])
stream.on_signal { |signal, data| execute_trade(signal, data) }

# Feed live data
stream.update(price: 150.25, volume: 1_000_000)
```

### Full Pipeline: Generate → Optimize → Stream

```ruby
# 1. Discover patterns
generator = SQA::StrategyGenerator.new(stock: stock)
patterns = generator.discover_patterns

# 2. Generate strategy
discovered_strategy = generator.generate_strategy(pattern_index: 0)

# 3. Optimize with GP
gp = SQA::GeneticProgram.new(stock: stock)
# ... optimize discovered strategy parameters ...
optimized_strategy = gp.evolve

# 4. Deploy to real-time stream
stream = SQA::Stream.new(ticker: 'AAPL', strategies: [optimized_strategy])
stream.on_signal { |signal, data| execute_trade(signal, data) }
```

## Data Requirements

All examples require:
- Alpha Vantage API key: `export AV_API_KEY=your_key_here`
- Or use local CSV data in `~/sqa_data/`

## Output Files

Examples may create output files in `/tmp/`:
- `/tmp/sqa_discovered_patterns.csv` - Exported patterns
- `/tmp/sqa_evolution_history.csv` - GP evolution history
- `/tmp/sqa_backtest_results.csv` - Backtest results

## Next Steps

After running these examples:

1. **Customize Parameters**: Adjust thresholds, periods, and constraints
2. **Test on Multiple Stocks**: Validate patterns across different securities
3. **Walk-Forward Validation**: Test on out-of-sample data
4. **Combine Techniques**: Use strategy generator + GP + KBS together
5. **Production Deployment**: Connect to real WebSocket data feeds

## Educational Disclaimer

⚠️ **Important**: All examples are for educational purposes only. Past performance does not guarantee future results. Always paper trade and thoroughly test before risking real capital.

## Contributing

Found a bug or have an improvement? Please submit an issue or pull request!
