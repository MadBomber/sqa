# frozen_string_literal: true

module Api
  module V1
    class StocksController < ActionController::API
      before_action :set_ticker, except: []

      # GET /api/v1/stock/:ticker
      def show
        stock = SQA::Stock.new(ticker: @ticker)
        df = stock.df

        # Get price data
        dates = df['date'].to_a.map(&:to_s)
        opens = df['open_price'].to_a
        highs = df['high_price'].to_a
        lows = df['low_price'].to_a
        closes = df['adj_close_price'].to_a
        volumes = df['volume'].to_a

        # Calculate basic stats
        current_price = closes.last
        prev_price = closes[-2]
        change = current_price - prev_price
        change_pct = (change / prev_price) * 100

        render json: {
          ticker: @ticker,
          current_price: current_price,
          change: change,
          change_percent: change_pct,
          high_52w: closes.last(252).max,
          low_52w: closes.last(252).min,
          dates: dates,
          open: opens,
          high: highs,
          low: lows,
          close: closes,
          volume: volumes
        }
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end

      # GET /api/v1/indicators/:ticker
      def indicators
        stock = SQA::Stock.new(ticker: @ticker)
        df = stock.df

        prices = df['adj_close_price'].to_a
        highs = df['high_price'].to_a
        lows = df['low_price'].to_a
        dates = df['date'].to_a.map(&:to_s)

        # Calculate indicators
        rsi = SQAI.rsi(prices, period: 14)
        macd_result = SQAI.macd(prices)
        bb_result = SQAI.bbands(prices)
        sma_20 = SQAI.sma(prices, period: 20)
        sma_50 = SQAI.sma(prices, period: 50)
        ema_20 = SQAI.ema(prices, period: 20)

        render json: {
          dates: dates,
          rsi: rsi,
          macd: macd_result[0],
          macd_signal: macd_result[1],
          macd_hist: macd_result[2],
          bb_upper: bb_result[0],
          bb_middle: bb_result[1],
          bb_lower: bb_result[2],
          sma_20: sma_20,
          sma_50: sma_50,
          ema_20: ema_20
        }
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end

      # POST /api/v1/backtest/:ticker
      def backtest
        stock = SQA::Stock.new(ticker: @ticker)
        strategy_name = params[:strategy] || 'RSI'

        strategy = resolve_strategy(strategy_name)

        backtest_runner = SQA::Backtest.new(
          stock: stock,
          strategy: strategy,
          initial_capital: 10_000.0,
          commission: 1.0
        )

        results = backtest_runner.run

        render json: {
          total_return: results.total_return,
          annualized_return: results.annualized_return,
          sharpe_ratio: results.sharpe_ratio,
          max_drawdown: results.max_drawdown,
          win_rate: results.win_rate,
          total_trades: results.total_trades,
          profit_factor: results.profit_factor,
          avg_win: results.avg_win,
          avg_loss: results.avg_loss
        }
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end

      # GET /api/v1/analyze/:ticker
      def analyze
        stock = SQA::Stock.new(ticker: @ticker)
        prices = stock.df['adj_close_price'].to_a

        # Market regime
        regime = SQA::MarketRegime.detect(stock)

        # Seasonal analysis
        seasonal = SQA::SeasonalAnalyzer.analyze(stock)

        # FPOP analysis
        fpop_data = SQA::FPOP.fpl_analysis(prices, fpop: 10)
        recent_fpop = fpop_data.last(10).map do |f|
          {
            direction: f[:direction],
            magnitude: f[:magnitude],
            risk: f[:risk],
            interpretation: f[:interpretation]
          }
        end

        # Risk metrics
        returns = prices.each_cons(2).map { |a, b| (b - a) / a }
        var_95 = SQA::RiskManager.var(returns, confidence: 0.95)
        sharpe = SQA::RiskManager.sharpe_ratio(returns)
        max_dd = SQA::RiskManager.max_drawdown(prices)

        render json: {
          regime: {
            type: regime[:type],
            volatility: regime[:volatility],
            strength: regime[:strength],
            trend: regime[:trend]
          },
          seasonal: {
            best_months: seasonal[:best_months],
            worst_months: seasonal[:worst_months],
            best_quarters: seasonal[:best_quarters],
            has_pattern: seasonal[:has_seasonal_pattern]
          },
          fpop: recent_fpop,
          risk: {
            var_95: var_95,
            sharpe_ratio: sharpe,
            max_drawdown: max_dd[:max_drawdown]
          }
        }
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end

      # POST /api/v1/compare/:ticker
      def compare
        stock = SQA::Stock.new(ticker: @ticker)

        strategies = {
          'RSI' => SQA::Strategy::RSI,
          'SMA' => SQA::Strategy::SMA,
          'EMA' => SQA::Strategy::EMA,
          'MACD' => SQA::Strategy::MACD,
          'BollingerBands' => SQA::Strategy::BollingerBands
        }

        results = strategies.map do |name, strategy_class|
          backtest_runner = SQA::Backtest.new(
            stock: stock,
            strategy: strategy_class,
            initial_capital: 10_000.0,
            commission: 1.0
          )

          result = backtest_runner.run

          {
            strategy: name,
            return: result.total_return,
            sharpe: result.sharpe_ratio,
            drawdown: result.max_drawdown,
            win_rate: result.win_rate,
            trades: result.total_trades
          }
        rescue => e
          nil
        end.compact

        results.sort_by! { |r| -r[:return] }
        render json: results
      rescue => e
        render json: { error: e.message }, status: :internal_server_error
      end

      private

      def set_ticker
        @ticker = params[:ticker].upcase
      end

      def resolve_strategy(name)
        case name.upcase
        when 'RSI' then SQA::Strategy::RSI
        when 'SMA' then SQA::Strategy::SMA
        when 'EMA' then SQA::Strategy::EMA
        when 'MACD' then SQA::Strategy::MACD
        when 'BOLLINGERBANDS' then SQA::Strategy::BollingerBands
        when 'STOCHASTIC' then SQA::Strategy::Stochastic
        when 'VOLUMEBREAKOUT' then SQA::Strategy::VolumeBreakout
        when 'KBS' then SQA::Strategy::KBS
        when 'CONSENSUS' then SQA::Strategy::Consensus
        when 'RANDOM' then SQA::Strategy::Random
        else
          SQA::Strategy::RSI
        end
      end
    end
  end
end
