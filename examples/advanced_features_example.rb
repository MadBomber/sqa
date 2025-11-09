#!/usr/bin/env ruby
# examples/advanced_features_example.rb
# frozen_string_literal: true

#####################################################################
###
##  File: advanced_features_example.rb
##  Desc: Comprehensive examples of advanced SQA features
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'sqa'
require 'ostruct'

puts "\n" + "=" * 70
puts "SQA Advanced Features Examples"
puts "=" * 70

# Initialize SQA
SQA.init

#############################################################
## Example 1: Risk Management
##

puts "\n" + "-" * 70
puts "Example 1: Risk Management"
puts "-" * 70

# Load stock data
stock = SQA::Stock.new(ticker: 'AAPL')
prices = stock.df["adj_close_price"].to_a

# Calculate returns
returns = prices.each_cons(2).map { |a, b| (b - a) / a }

puts "\n1.1 Value at Risk (VaR)"
var_95 = SQA::RiskManager.var(returns, confidence: 0.95, method: :historical)
var_99 = SQA::RiskManager.var(returns, confidence: 0.99, method: :historical)
puts "  95% VaR: #{(var_95 * 100).round(2)}% (max expected daily loss)"
puts "  99% VaR: #{(var_99 * 100).round(2)}% (max expected daily loss)"

puts "\n1.2 Conditional VaR (CVaR / Expected Shortfall)"
cvar_95 = SQA::RiskManager.cvar(returns, confidence: 0.95)
puts "  95% CVaR: #{(cvar_95 * 100).round(2)}% (avg loss in worst 5% of days)"

puts "\n1.3 Position Sizing - Kelly Criterion"
# Calculate win rate and avg win/loss from recent trades
winning_returns = returns.select { |r| r > 0 }
losing_returns = returns.select { |r| r < 0 }

win_rate = winning_returns.size.to_f / returns.size
avg_win = winning_returns.sum / winning_returns.size.to_f
avg_loss = losing_returns.sum / losing_returns.size.to_f

position_size = SQA::RiskManager.kelly_criterion(
  win_rate: win_rate,
  avg_win: avg_win.abs,
  avg_loss: avg_loss.abs,
  capital: 10_000,
  max_fraction: 0.25
)
puts "  Optimal position size: $#{position_size.round(2)}"
puts "  Win rate: #{(win_rate * 100).round(1)}%"
puts "  Avg win: #{(avg_win * 100).round(2)}%"
puts "  Avg loss: #{(avg_loss * 100).round(2)}%"

puts "\n1.4 Maximum Drawdown"
dd_result = SQA::RiskManager.max_drawdown(prices)
puts "  Max drawdown: #{(dd_result[:max_drawdown] * 100).round(2)}%"
puts "  Peak price: $#{dd_result[:peak_value].round(2)}"
puts "  Trough price: $#{dd_result[:trough_value].round(2)}"

puts "\n1.5 Risk Metrics"
sharpe = SQA::RiskManager.sharpe_ratio(returns, risk_free_rate: 0.02)
sortino = SQA::RiskManager.sortino_ratio(returns, target_return: 0.0)
calmar = SQA::RiskManager.calmar_ratio(returns)
puts "  Sharpe Ratio: #{sharpe.round(2)}"
puts "  Sortino Ratio: #{sortino.round(2)}"
puts "  Calmar Ratio: #{calmar.round(2)}"

puts "\n1.6 Monte Carlo Simulation"
simulation = SQA::RiskManager.monte_carlo_simulation(
  initial_capital: 10_000,
  returns: returns,
  periods: 252,  # 1 year
  simulations: 1000
)
puts "  Median outcome (1 year): $#{simulation[:median].round(2)}"
puts "  95% confidence interval: $#{simulation[:percentile_5].round(2)} - $#{simulation[:percentile_95].round(2)}"
puts "  Best case: $#{simulation[:max].round(2)}"
puts "  Worst case: $#{simulation[:min].round(2)}"

#############################################################
## Example 2: Portfolio Optimization
##

puts "\n" + "-" * 70
puts "Example 2: Portfolio Optimization"
puts "-" * 70

# Load multiple stocks
tickers = ['AAPL', 'MSFT', 'GOOGL']
stocks = tickers.map { |t| SQA::Stock.new(ticker: t) }

# Get returns for each stock (last 100 days)
returns_matrix = stocks.map do |stock|
  prices = stock.df["adj_close_price"].to_a.last(100)
  prices.each_cons(2).map { |a, b| (b - a) / a }
end

puts "\n2.1 Maximum Sharpe Ratio Portfolio"
max_sharpe = SQA::PortfolioOptimizer.maximum_sharpe(returns_matrix, risk_free_rate: 0.02)
puts "  Optimal weights:"
tickers.each_with_index do |ticker, i|
  puts "    #{ticker}: #{(max_sharpe[:weights][i] * 100).round(1)}%"
end
puts "  Sharpe ratio: #{max_sharpe[:sharpe].round(2)}"
puts "  Expected return: #{(max_sharpe[:return] * 100).round(2)}%"
puts "  Volatility: #{(max_sharpe[:volatility] * 100).round(2)}%"

puts "\n2.2 Minimum Variance Portfolio"
min_var = SQA::PortfolioOptimizer.minimum_variance(returns_matrix)
puts "  Optimal weights:"
tickers.each_with_index do |ticker, i|
  puts "    #{ticker}: #{(min_var[:weights][i] * 100).round(1)}%"
end
puts "  Volatility: #{(min_var[:volatility] * 100).round(2)}%"

puts "\n2.3 Risk Parity Portfolio"
risk_parity = SQA::PortfolioOptimizer.risk_parity(returns_matrix)
puts "  Optimal weights:"
tickers.each_with_index do |ticker, i|
  puts "    #{ticker}: #{(risk_parity[:weights][i] * 100).round(1)}%"
end

puts "\n2.4 Multi-Objective Optimization"
multi_obj = SQA::PortfolioOptimizer.multi_objective(
  returns_matrix,
  objectives: {
    maximize_return: 0.4,
    minimize_volatility: 0.3,
    minimize_drawdown: 0.3
  }
)
puts "  Optimal weights:"
tickers.each_with_index do |ticker, i|
  puts "    #{ticker}: #{(multi_obj[:weights][i] * 100).round(1)}%"
end
puts "  Expected return: #{(multi_obj[:return] * 100).round(2)}%"
puts "  Volatility: #{(multi_obj[:volatility] * 100).round(2)}%"
puts "  Max drawdown: #{(multi_obj[:max_drawdown] * 100).round(2)}%"

#############################################################
## Example 3: Ensemble Methods
##

puts "\n" + "-" * 70
puts "Example 3: Ensemble Strategy Combination"
puts "-" * 70

# Create ensemble of strategies
ensemble = SQA::Ensemble.new(
  strategies: [SQA::Strategy::RSI, SQA::Strategy::MACD, SQA::Strategy::SMA],
  voting_method: :majority
)

# Create vector for signal generation
prices = stock.df["adj_close_price"].to_a
vector = OpenStruct.new(
  prices: prices,
  close: prices.last,
  rsi: SQAI.rsi(prices, period: 14).last,
  macd: SQAI.macd(prices, fast_period: 12, slow_period: 26).last,
  macd_signal: SQAI.ema(prices, period: 9).last,
  sma_20: SQAI.sma(prices, period: 20).last,
  sma_50: SQAI.sma(prices, period: 50).last
)

puts "\n3.1 Majority Voting"
signal = ensemble.majority_vote(vector)
puts "  Ensemble signal: #{signal}"

puts "\n3.2 Weighted Voting"
ensemble.instance_variable_set(:@voting_method, :weighted)
ensemble.instance_variable_set(:@weights, [0.5, 0.3, 0.2])  # Give more weight to RSI
signal = ensemble.weighted_vote(vector)
puts "  Weighted signal (RSI 50%, MACD 30%, SMA 20%): #{signal}"

puts "\n3.3 Strategy Rotation Based on Market Conditions"
selected_strategy = ensemble.rotate(stock)
puts "  Selected strategy for current market: #{selected_strategy}"

#############################################################
## Example 4: Multi-Timeframe Analysis
##

puts "\n" + "-" * 70
puts "Example 4: Multi-Timeframe Analysis"
puts "-" * 70

mta = SQA::MultiTimeframe.new(stock: stock)

puts "\n4.1 Trend Alignment"
alignment = mta.trend_alignment(lookback: 20)
puts "  Daily trend: #{alignment[:daily]}"
puts "  Weekly trend: #{alignment[:weekly]}"
puts "  Monthly trend: #{alignment[:monthly]}"
puts "  All timeframes aligned? #{alignment[:aligned]}"
puts "  Overall direction: #{alignment[:direction]}"

puts "\n4.2 Multi-Timeframe Signal"
signal = mta.signal(
  strategy_class: SQA::Strategy::RSI,
  higher_timeframe: :weekly,
  lower_timeframe: :daily
)
puts "  Signal (weekly trend + daily timing): #{signal}"

puts "\n4.3 Support/Resistance Across Timeframes"
levels = mta.support_resistance(tolerance: 0.02)
puts "  Current price: $#{levels[:current_price].round(2)}"
puts "  Support levels (from multiple timeframes):"
levels[:support].first(3).each do |level|
  puts "    $#{level[:price].round(2)} (appears in #{level[:count]} timeframes)"
end
puts "  Resistance levels (from multiple timeframes):"
levels[:resistance].first(3).each do |level|
  puts "    $#{level[:price].round(2)} (appears in #{level[:count]} timeframes)"
end

puts "\n4.4 Divergence Detection"
divergences = mta.detect_divergence
divergences.each do |timeframe, divergence|
  puts "  #{timeframe}: #{divergence}"
end

#############################################################
## Example 5: Pattern Similarity Search
##

puts "\n" + "-" * 70
puts "Example 5: Pattern Similarity Search"
puts "-" * 70

matcher = SQA::PatternMatcher.new(stock: stock)

puts "\n5.1 Find Similar Historical Patterns"
similar = matcher.find_similar(lookback: 10, num_matches: 5, method: :euclidean)
puts "  Found #{similar.size} similar 10-day patterns:"
similar.each_with_index do |match, i|
  puts "  #{i + 1}. Distance: #{match[:distance].round(4)}, Future return: #{(match[:future_return] * 100).round(2)}%"
end

puts "\n5.2 Forecast Based on Similar Patterns"
forecast = matcher.forecast(lookback: 10, forecast_periods: 5, num_matches: 10)
current_price = forecast[:current_price]
forecast_price = forecast[:forecast_price]
lower, upper = forecast[:confidence_interval_95]

puts "  Current price: $#{current_price.round(2)}"
puts "  Forecast price (5 days): $#{forecast_price.round(2)} (#{((forecast_price - current_price) / current_price * 100).round(2)}%)"
puts "  95% confidence interval: $#{lower.round(2)} - $#{upper.round(2)}"
puts "  Based on #{forecast[:num_matches]} similar historical patterns"

puts "\n5.3 Chart Pattern Detection"
[:double_top, :double_bottom, :head_and_shoulders, :triangle].each do |pattern_type|
  patterns = matcher.detect_chart_pattern(pattern_type)
  if patterns.any?
    puts "  Found #{patterns.size} #{pattern_type.to_s.gsub('_', ' ')} pattern(s)"
    patterns.first(2).each do |pattern|
      puts "    - #{pattern.inspect}"
    end
  else
    puts "  No #{pattern_type.to_s.gsub('_', ' ')} patterns detected"
  end
end

puts "\n5.4 Pattern Clustering"
clusters = matcher.cluster_patterns(pattern_length: 10, num_clusters: 5)
puts "  Clustered patterns into #{clusters.size} groups:"
clusters.each_with_index do |cluster, i|
  puts "    Cluster #{i + 1}: #{cluster.size} similar patterns"
end

#############################################################
## Example 6: Combined Advanced Workflow
##

puts "\n" + "-" * 70
puts "Example 6: Complete Advanced Workflow"
puts "-" * 70
puts "(Combining all features for optimal trading decision)"

puts "\n6.1 Risk Assessment"
var_95 = SQA::RiskManager.var(returns, confidence: 0.95)
cvar_95 = SQA::RiskManager.cvar(returns, confidence: 0.95)
puts "  VaR (95%): #{(var_95 * 100).round(2)}%"
puts "  CVaR (95%): #{(cvar_95 * 100).round(2)}%"

# Position size based on risk
position_size = SQA::RiskManager.fixed_fractional(capital: 10_000, risk_fraction: 0.02)
puts "  Position size (2% risk): $#{position_size.round(2)}"

puts "\n6.2 Multi-Timeframe Confirmation"
alignment = mta.trend_alignment
if alignment[:aligned]
  puts "  ✓ All timeframes aligned #{alignment[:direction]}"
else
  puts "  ✗ Mixed timeframe signals - exercise caution"
end

puts "\n6.3 Ensemble Strategy Signal"
signal = ensemble.signal(vector)
puts "  Ensemble recommendation: #{signal.to_s.upcase}"

puts "\n6.4 Pattern-Based Forecast"
forecast = matcher.forecast(lookback: 10, forecast_periods: 5)
expected_return = forecast[:forecast_return]
puts "  Expected return (5 days): #{(expected_return * 100).round(2)}%"

puts "\n6.5 Final Trading Decision"
decision = if signal == :buy && alignment[:aligned] && expected_return > 0.02
             "STRONG BUY"
           elsif signal == :buy && expected_return > 0.01
             "BUY"
           elsif signal == :sell && expected_return < -0.02
             "STRONG SELL"
           elsif signal == :sell
             "SELL"
           else
             "HOLD"
           end

puts "  Final decision: #{decision}"
puts "  Position size: $#{position_size.round(2)}"
puts "  Stop loss: $#{(prices.last * (1 + var_95)).round(2)}"
puts "  Target: $#{(prices.last * (1 + expected_return)).round(2)}"

puts "\n" + "=" * 70
puts "Advanced Features Examples Complete!"
puts "=" * 70
puts "\nThese examples demonstrate:"
puts "1. Risk Management: VaR, CVaR, position sizing, risk metrics"
puts "2. Portfolio Optimization: Sharpe, min variance, risk parity, multi-objective"
puts "3. Ensemble Methods: Strategy combination, voting, rotation"
puts "4. Multi-Timeframe Analysis: Trend alignment, multi-TF signals, S/R levels"
puts "5. Pattern Matching: Similar patterns, forecasting, chart patterns"
puts "6. Complete workflow combining all features"
puts "\n"
