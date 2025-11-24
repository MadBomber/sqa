# 📚 API Reference

Complete API documentation for all SQA classes and modules.

!!! tip "Auto-Generated Documentation"
    This documentation is automatically generated from YARD comments in the source code.
    Last updated: 2025-11-24 17:07:39

## 🎯 SQA

### [📦 **Backtest**](sqa_backtest.md)

### [📦 **BadParameterError**](sqa_badparametererror.md)

!!! abstract ""
    Raised when a method parameter is invalid.

### [📦 **Config**](sqa_config.md)

!!! abstract ""
    Configuration class for SQA settings.

### [📦 **ConfigurationError**](sqa_configurationerror.md)

!!! abstract ""
    Raised when SQA configuration is invalid or missing.

### [📦 **DataFetchError**](sqa_datafetcherror.md)

!!! abstract ""
    Raised when unable to fetch data from a data source (API, file, etc.).

### [📦 **DataFrame**](sqa_dataframe.md)

!!! abstract ""
    High-performance DataFrame wrapper around Polars for time series data manipulation.

### [📦 **Ensemble**](sqa_ensemble.md)

!!! abstract ""
    Ensemble - Combine multiple trading strategies

### [🔧 **FPOP**](sqa_fpop.md)

### [📦 **GeneticProgram**](sqa_geneticprogram.md)

### [🔧 **MarketRegime**](sqa_marketregime.md)

### [📦 **MultiTimeframe**](sqa_multitimeframe.md)

!!! abstract ""
    MultiTimeframe - Analyze patterns across multiple timeframes

### [📦 **PatternMatcher**](sqa_patternmatcher.md)

!!! abstract ""
    PatternMatcher - Find similar historical patterns

### [📦 **PluginManager**](sqa_pluginmanager.md)

### [📦 **Portfolio**](sqa_portfolio.md)

### [📦 **PortfolioOptimizer**](sqa_portfoliooptimizer.md)

!!! abstract ""
    PortfolioOptimizer - Multi-objective portfolio optimization

### [📦 **RiskManager**](sqa_riskmanager.md)

!!! abstract ""
    RiskManager - Comprehensive risk management and position sizing

### [🔧 **SeasonalAnalyzer**](sqa_seasonalanalyzer.md)

### [📦 **SectorAnalyzer**](sqa_sectoranalyzer.md)

### [📦 **Stock**](sqa_stock.md)

!!! abstract ""
    Represents a stock with price history, metadata, and technical analysis capabilities.

### [📦 **Strategy**](sqa_strategy.md)

!!! abstract ""
    This module needs to be extend'ed within

### [📦 **StrategyGenerator**](sqa_strategygenerator.md)

### [📦 **Stream**](sqa_stream.md)

### [📦 **Ticker**](sqa_ticker.md)

!!! abstract ""
    sqa/lib/sqa/ticker.rb


## 📦 SQA::GeneticProgram

### [📦 **Individual**](sqa_geneticprogram_individual.md)

!!! abstract ""
    Represents an individual trading strategy with specific parameters


## 📦 Top Level

### [📦 **AlphaVantageAPI**](alphavantageapi.md)

### [📦 **ApiError**](apierror.md)

!!! abstract ""
    Raised when an external API returns an error response.

### [📦 **NotImplemented**](notimplemented.md)

!!! abstract ""
    Raised when a feature is not yet implemented.

### [🔧 **SQA**](sqa.md)

!!! abstract ""
    Knowledge-Based Strategy using RETE Forward Chaining

### [📦 **String**](string.md)

!!! abstract ""
    File:  string.rb


## 📦 SQA::Backtest

### [📦 **Results**](sqa_backtest_results.md)

!!! abstract ""
    Represents the results of a backtest


## 📦 SQA::Portfolio

### [📦 **Position**](sqa_portfolio_position.md)

!!! abstract ""
    Represents a single position in the portfolio

### [📦 **Trade**](sqa_portfolio_trade.md)

!!! abstract ""
    Represents a single trade


## 📊 SQA::Strategy

### [📦 **BollingerBands**](sqa_strategy_bollingerbands.md)

!!! abstract ""
    Bollinger Bands trading strategy

### [🔧 **Common**](sqa_strategy_common.md)

### [📦 **Consensus**](sqa_strategy_consensus.md)

### [📦 **EMA**](sqa_strategy_ema.md)

### [📦 **KBS**](sqa_strategy_kbs.md)

### [📦 **MACD**](sqa_strategy_macd.md)

!!! abstract ""
    MACD (Moving Average Convergence Divergence) crossover strategy

### [📦 **MP**](sqa_strategy_mp.md)

### [📦 **MR**](sqa_strategy_mr.md)

### [📦 **RSI**](sqa_strategy_rsi.md)

### [📦 **Random**](sqa_strategy_random.md)

### [📦 **SMA**](sqa_strategy_sma.md)

### [📦 **Stochastic**](sqa_strategy_stochastic.md)

!!! abstract ""
    Stochastic Oscillator crossover strategy

### [📦 **VolumeBreakout**](sqa_strategy_volumebreakout.md)

!!! abstract ""
    Volume Breakout strategy


## 📦 SQA::DataFrame

### [📦 **AlphaVantage**](sqa_dataframe_alphavantage.md)

### [📦 **Data**](sqa_dataframe_data.md)

!!! abstract ""
    Data class to store stock metadata

### [📦 **YahooFinance**](sqa_dataframe_yahoofinance.md)


## 📊 SQA::StrategyGenerator

### [📦 **Pattern**](sqa_strategygenerator_pattern.md)

!!! abstract ""
    Represents a discovered indicator pattern

### [📦 **PatternContext**](sqa_strategygenerator_patterncontext.md)

!!! abstract ""
    Pattern Context - metadata about when/where pattern is valid

### [📦 **ProfitablePoint**](sqa_strategygenerator_profitablepoint.md)

!!! abstract ""
    Represents a profitable trade opportunity discovered in historical data


