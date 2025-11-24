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

### 5. FPL Analysis (`fpop_analysis_example.rb`)

**Analyze Future Period Loss/Profit to identify high-quality trading opportunities**

This example demonstrates how to use the FPL (Future Period Loss/Profit) analysis utilities to discover optimal entry points with controlled risk:

- Calculate min/max price changes over future periods
- Filter opportunities by magnitude and risk thresholds
- Identify inflection points (local minima/maxima)
- Analyze directional bias (UP, DOWN, UNCERTAIN, FLAT)
- Risk management with max FPL risk constraints

**Run it:**
```bash
./examples/fpop_analysis_example.rb
```

**Key Examples:**
- Example 1: Basic FPL calculation
- Example 2: DataFrame FPL convenience methods
- Example 3: Comprehensive FPL analysis
- Example 4: Quality filtering (magnitude, risk, direction)
- Example 5: Integration with Strategy Generator

**Output:**
- FPL arrays (min/max deltas per price point)
- Risk metrics and directional analysis
- Filtered high-quality opportunities
- Integration with pattern discovery

---

### 6. Pattern Context System (`pattern_context_example.rb`)

**Discover context-aware trading patterns with market regime, seasonal, and sector analysis**

This comprehensive example demonstrates the Pattern Context system that addresses the reality that trading patterns are not universal - they depend on market conditions, seasonality, and sector behavior:

- **Market Regime Detection**: Identify bull/bear/sideways markets with volatility classification
- **Seasonal Analysis**: Discover calendar-dependent patterns (monthly/quarterly performance)
- **Sector Analysis**: Cross-stock pattern discovery with separate KBS blackboards per sector
- **Walk-Forward Validation**: Prevent overfitting with time-series cross-validation
- **Context-Aware Patterns**: Patterns know when they're valid (regime, season, sector)

**Run it:**
```bash
./examples/pattern_context_example.rb
```

**Key Examples:**
- Example 1: Market regime detection and history
- Example 2: Seasonal pattern analysis
- Example 3: Sector analysis with KBS blackboards
- Example 4: Context-aware pattern discovery
- Example 5: Walk-forward validation
- Example 6: Runtime pattern validation

**Output:**
- Market regime classification (bull/bear/sideways)
- Best/worst months and quarters
- Sector-wide patterns across multiple stocks
- Validated patterns that work out-of-sample
- Runtime validation results

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

### Combining FPL + Pattern Discovery

```ruby
# Use FPL analysis to filter high-quality opportunities
generator = SQA::StrategyGenerator.new(
  stock: stock,
  min_gain_percent: 8.0,
  fpop: 10,
  max_fpl_risk: 25.0  # Filter by risk
)

patterns = generator.discover_patterns
# Only includes opportunities with FPL risk ≤ 25%
```

### Combining Pattern Context + Sector Analysis

```ruby
# Discover sector-wide patterns with context
analyzer = SQA::SectorAnalyzer.new
tech_stocks = ['AAPL', 'MSFT', 'GOOGL'].map { |t| SQA::Stock.new(ticker: t) }

tech_stocks.each { |stock| analyzer.add_stock(stock.ticker, sector: :technology) }

# Find patterns that work across the sector
patterns = analyzer.discover_sector_patterns(
  :technology,
  tech_stocks,
  analyze_regime: true,
  analyze_seasonal: true
)

# Patterns have full context metadata
patterns.first.context.market_regime   # => :bull
patterns.first.context.sector          # => :technology
patterns.first.context.valid_months    # => [10, 11, 12]
```

### Full Pipeline: Generate → Optimize → Validate → Stream

```ruby
# 1. Discover context-aware patterns
generator = SQA::StrategyGenerator.new(stock: stock, fpop: 10)
patterns = generator.discover_context_aware_patterns(
  analyze_regime: true,
  analyze_seasonal: true,
  sector: :technology
)

# 2. Walk-forward validate
validated = generator.walk_forward_validate(
  train_size: 250,
  test_size: 60,
  step_size: 30
)

# 3. Generate strategy from best validated pattern
discovered_strategy = generator.generate_strategy(pattern_index: 0)

# 4. Optimize with GP
gp = SQA::GeneticProgram.new(stock: stock)
# ... optimize discovered strategy parameters ...
optimized_strategy = gp.evolve

# 5. Deploy to real-time stream with runtime validation
stream = SQA::Stream.new(ticker: 'AAPL', strategies: [optimized_strategy])
stream.on_signal do |signal, data|
  # Check if pattern is valid for current conditions
  regime = SQA::MarketRegime.detect(stock)
  if patterns.first.context.valid_for?(
    date: Date.today,
    regime: regime[:type],
    sector: :technology
  )
    execute_trade(signal, data)
  end
end
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

## Web Demo Application

For a complete web-based demonstration of SQA's capabilities, see the **[sqa_demo-sinatra](https://github.com/MadBomber/sqa_demo-sinatra)** gem. This Sinatra application provides a visual interface for:

- Stock analysis dashboard
- Technical indicator visualization
- Strategy backtesting
- Portfolio management

## Next Steps

After running these examples:

1. **Customize Parameters**: Adjust thresholds, periods, and constraints
2. **Test on Multiple Stocks**: Validate patterns across different securities
3. **Walk-Forward Validation**: Test on out-of-sample data
4. **Combine Techniques**: Use strategy generator + GP + KBS together
5. **Production Deployment**: Connect to real WebSocket data feeds
6. **Try the Web Demo**: Install [sqa_demo-sinatra](https://github.com/MadBomber/sqa_demo-sinatra) for a visual interface

## Educational Disclaimer

⚠️ **Important**: All examples are for educational purposes only. Past performance does not guarantee future results. Always paper trade and thoroughly test before risking real capital.

## Contributing

Found a bug or have an improvement? Please submit an issue or pull request!
