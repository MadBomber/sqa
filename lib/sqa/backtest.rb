# lib/sqa/backtest.rb
# frozen_string_literal: true

require 'date'
require_relative 'portfolio'

class SQA::Backtest
  attr_reader :stock, :strategy, :portfolio, :results, :equity_curve

  # Represents the results of a backtest
  class Results
    attr_accessor :total_return, :annualized_return, :sharpe_ratio, :max_drawdown,
                  :total_trades, :winning_trades, :losing_trades, :win_rate,
                  :average_win, :average_loss, :profit_factor,
                  :start_date, :end_date, :initial_capital, :final_value

    def initialize
      @total_return = 0.0
      @annualized_return = 0.0
      @sharpe_ratio = 0.0
      @max_drawdown = 0.0
      @total_trades = 0
      @winning_trades = 0
      @losing_trades = 0
      @win_rate = 0.0
      @average_win = 0.0
      @average_loss = 0.0
      @profit_factor = 0.0
    end

    def to_h
      {
        total_return: total_return,
        annualized_return: annualized_return,
        sharpe_ratio: sharpe_ratio,
        max_drawdown: max_drawdown,
        total_trades: total_trades,
        winning_trades: winning_trades,
        losing_trades: losing_trades,
        win_rate: win_rate,
        average_win: average_win,
        average_loss: average_loss,
        profit_factor: profit_factor,
        start_date: start_date,
        end_date: end_date,
        initial_capital: initial_capital,
        final_value: final_value
      }
    end

    def summary
      <<~SUMMARY
        Backtest Results
        ================
        Period: #{start_date} to #{end_date}
        Initial Capital: $#{initial_capital.round(2)}
        Final Value: $#{final_value.round(2)}

        Performance Metrics:
        - Total Return: #{(total_return * 100).round(2)}%
        - Annualized Return: #{(annualized_return * 100).round(2)}%
        - Sharpe Ratio: #{sharpe_ratio.round(2)}
        - Maximum Drawdown: #{(max_drawdown * 100).round(2)}%

        Trade Statistics:
        - Total Trades: #{total_trades}
        - Winning Trades: #{winning_trades}
        - Losing Trades: #{losing_trades}
        - Win Rate: #{(win_rate * 100).round(2)}%
        - Average Win: $#{average_win.round(2)}
        - Average Loss: $#{average_loss.round(2)}
        - Profit Factor: #{profit_factor.round(2)}
      SUMMARY
    end
  end

  # Initialize a backtest
  # @param stock [SQA::Stock] Stock to backtest
  # @param strategy [SQA::Strategy, Proc] Strategy or callable that returns :buy, :sell, or :hold
  # @param start_date [Date, String] Start date for backtest
  # @param end_date [Date, String] End date for backtest
  # @param initial_capital [Float] Starting capital
  # @param commission [Float] Commission per trade
  # @param position_size [Symbol, Float] :all_cash or fraction of portfolio per trade
  def initialize(stock:, strategy:, start_date: nil, end_date: nil,
                 initial_capital: 10_000.0, commission: 0.0, position_size: :all_cash)
    @stock = stock
    @strategy = strategy
    @start_date = start_date ? Date.parse(start_date.to_s) : Date.parse(stock.df["timestamp"].first)
    @end_date = end_date ? Date.parse(end_date.to_s) : Date.parse(stock.df["timestamp"].last)
    @initial_capital = initial_capital
    @commission = commission
    @position_size = position_size

    @portfolio = SQA::Portfolio.new(initial_cash: initial_capital, commission: commission)
    @equity_curve = []  # Track portfolio value over time
    @results = Results.new
  end

  # Run the backtest
  # @return [Results] Backtest results
  #
  # @example Run backtest with RSI strategy
  #   stock = SQA::Stock.new(ticker: 'AAPL')
  #   backtest = SQA::Backtest.new(
  #     stock: stock,
  #     strategy: SQA::Strategy::RSI,
  #     initial_capital: 10_000,
  #     commission: 1.0
  #   )
  #   results = backtest.run
  #   puts results.summary
  #   # => Total Return: 15.5%
  #   #    Sharpe Ratio: 1.2
  #   #    Max Drawdown: -8.3%
  #   #    Win Rate: 65%
  #
  # @example Backtest with custom date range
  #   backtest = SQA::Backtest.new(
  #     stock: stock,
  #     strategy: SQA::Strategy::MACD,
  #     start_date: '2023-01-01',
  #     end_date: '2023-12-31'
  #   )
  #   results = backtest.run
  #   results.total_return  # => 0.155 (15.5%)
  #
  # @example Access equity curve for plotting
  #   results = backtest.run
  #   backtest.equity_curve.each do |point|
  #     puts "#{point[:date]}: $#{point[:value]}"
  #   end
  #
  def run
    # Get data for the backtest period
    df = @stock.df.data

    # Filter to backtest period
    timestamps = df["timestamp"].to_a
    start_idx = timestamps.index { |t| Date.parse(t) >= @start_date } || 0
    end_idx = timestamps.rindex { |t| Date.parse(t) <= @end_date } || timestamps.length - 1

    prices = df["adj_close_price"].to_a
    ticker = @stock.ticker.upcase

    # Track current position
    current_position = nil  # :long, :short, or nil

    # Run through each day
    (start_idx..end_idx).each do |i|
      date = Date.parse(timestamps[i])
      price = prices[i]

      # Get historical prices up to this point for strategy
      historical_prices = prices[0..i]

      # Generate signal from strategy
      signal = generate_signal(historical_prices)

      # Execute trades based on signal
      case signal
      when :buy
        if current_position.nil? && can_buy?(price)
          shares = calculate_shares_to_buy(price)
          @portfolio.buy(ticker, shares: shares, price: price, date: date)
          current_position = :long
        end

      when :sell
        if current_position == :long
          pos = @portfolio.position(ticker)
          @portfolio.sell(ticker, shares: pos.shares, price: price, date: date) if pos
          current_position = nil
        end
      end

      # Record equity curve
      current_value = @portfolio.value(ticker => price)
      @equity_curve << { date: date, value: current_value, price: price }
    end

    # Close any open positions at end
    if current_position == :long
      final_price = prices[end_idx]
      final_date = Date.parse(timestamps[end_idx])
      pos = @portfolio.position(ticker)
      @portfolio.sell(ticker, shares: pos.shares, price: final_price, date: final_date) if pos
    end

    # Calculate results
    calculate_results

    @results
  end

  private

  # Generate trading signal from strategy
  # @param historical_prices [Array<Float>] Price history
  # @return [Symbol] :buy, :sell, or :hold
  def generate_signal(historical_prices)
    if @strategy.respond_to?(:execute)
      # SQA::Strategy object
      require 'ostruct'

      # Calculate indicators for strategy
      vector = OpenStruct.new
      vector.prices = historical_prices

      # Add common indicators if we have enough data
      if historical_prices.length >= 14
        vector.rsi = SQAI.rsi(historical_prices, period: 14).last rescue nil
      end

      if historical_prices.length >= 20
        vector.sma_20 = SQAI.sma(historical_prices, period: 20).last rescue nil
      end

      if historical_prices.length >= 50
        vector.sma_50 = SQAI.sma(historical_prices, period: 50).last rescue nil
      end

      signals = @strategy.execute(vector)
      signals.first || :hold
    elsif @strategy.respond_to?(:call)
      # Proc or lambda
      @strategy.call(historical_prices)
    elsif @strategy.respond_to?(:trade)
      # Strategy class
      require 'ostruct'
      vector = OpenStruct.new(prices: historical_prices)

      if historical_prices.length >= 14
        vector.rsi = SQAI.rsi(historical_prices, period: 14).last rescue nil
      end

      @strategy.trade(vector)
    else
      :hold
    end
  end

  # Check if we can afford to buy at given price
  # @param price [Float] Stock price
  # @return [Boolean] True if we can buy
  def can_buy?(price)
    shares = calculate_shares_to_buy(price)
    shares > 0 && (shares * price + @commission) <= @portfolio.cash
  end

  # Calculate how many shares to buy
  # @param price [Float] Stock price
  # @return [Integer] Number of shares
  def calculate_shares_to_buy(price)
    if @position_size == :all_cash
      # Use all available cash
      max_shares = (@portfolio.cash - @commission) / price
      max_shares.floor
    else
      # Use fraction of portfolio
      capital_to_use = @portfolio.cash * @position_size
      max_shares = (capital_to_use - @commission) / price
      max_shares.floor
    end
  end

  # Calculate backtest results and metrics
  def calculate_results
    @results.initial_capital = @initial_capital
    @results.final_value = @equity_curve.last[:value]
    @results.start_date = @start_date
    @results.end_date = @end_date

    # Total return
    @results.total_return = (@results.final_value - @initial_capital) / @initial_capital

    # Annualized return
    days = (@end_date - @start_date).to_i
    years = days / 365.0
    if years > 0
      @results.annualized_return = ((1 + @results.total_return) ** (1.0 / years)) - 1
    end

    # Sharpe ratio (simplified - assumes risk-free rate of 0)
    returns = calculate_daily_returns
    if returns.any? && returns.map { |r| r ** 2 }.sum > 0
      avg_return = returns.sum / returns.size
      std_dev = Math.sqrt(returns.map { |r| (r - avg_return) ** 2 }.sum / returns.size)
      @results.sharpe_ratio = std_dev > 0 ? (avg_return / std_dev) * Math.sqrt(252) : 0.0
    end

    # Maximum drawdown
    @results.max_drawdown = calculate_max_drawdown

    # Trade statistics
    calculate_trade_statistics
  end

  # Calculate daily returns from equity curve
  # @return [Array<Float>] Array of daily returns
  def calculate_daily_returns
    returns = []
    @equity_curve.each_cons(2) do |prev, curr|
      returns << (curr[:value] - prev[:value]) / prev[:value]
    end
    returns
  end

  # Calculate maximum drawdown
  # @return [Float] Maximum drawdown as decimal
  def calculate_max_drawdown
    peak = @equity_curve.first[:value]
    max_dd = 0.0

    @equity_curve.each do |point|
      if point[:value] > peak
        peak = point[:value]
      else
        dd = (peak - point[:value]) / peak
        max_dd = dd if dd > max_dd
      end
    end

    max_dd
  end

  # Calculate trade statistics
  def calculate_trade_statistics
    trades = @portfolio.trade_history
    @results.total_trades = trades.count { |t| t.action == :sell }

    # Match buys with sells to calculate P&L per trade
    trade_pls = []
    buy_trades = trades.select { |t| t.action == :buy }
    sell_trades = trades.select { |t| t.action == :sell }

    sell_trades.each_with_index do |sell, i|
      if i < buy_trades.size
        buy = buy_trades[i]
        pl = (sell.price - buy.price) * sell.shares - sell.commission - buy.commission
        trade_pls << pl
      end
    end

    if trade_pls.any?
      winning = trade_pls.select { |pl| pl > 0 }
      losing = trade_pls.select { |pl| pl < 0 }

      @results.winning_trades = winning.size
      @results.losing_trades = losing.size
      @results.win_rate = winning.size.to_f / trade_pls.size
      @results.average_win = winning.any? ? winning.sum / winning.size : 0.0
      @results.average_loss = losing.any? ? losing.sum / losing.size : 0.0

      # Profit factor
      total_wins = winning.sum
      total_losses = losing.sum.abs
      @results.profit_factor = total_losses > 0 ? total_wins / total_losses : 0.0
    end
  end
end
