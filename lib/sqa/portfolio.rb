# lib/sqa/portfolio.rb
# frozen_string_literal: true

require 'date'
require 'csv'

class SQA::Portfolio
  attr_accessor :positions, :trades, :cash, :initial_cash, :commission

  # Represents a single position in the portfolio
  Position = Struct.new(:ticker, :shares, :avg_cost, :total_cost) do
    def value(current_price)
      shares * current_price
    end

    def profit_loss(current_price)
      (current_price - avg_cost) * shares
    end

    def profit_loss_percent(current_price)
      return 0.0 if avg_cost.zero?
      ((current_price - avg_cost) / avg_cost) * 100.0
    end
  end

  # Represents a single trade
  Trade = Struct.new(:ticker, :action, :shares, :price, :date, :total, :commission) do
    def to_h
      {
        ticker: ticker,
        action: action,
        shares: shares,
        price: price,
        date: date,
        total: total,
        commission: commission
      }
    end
  end

  def initialize(initial_cash: 10_000.0, commission: 0.0)
    @initial_cash = initial_cash
    @cash = initial_cash
    @commission = commission  # Commission per trade (flat fee or percentage)
    @positions = {}  # { ticker => Position }
    @trades = []     # Array of Trade objects
  end

  # Buy shares of a stock
  # @param ticker [String] Stock ticker symbol
  # @param shares [Integer] Number of shares to buy
  # @param price [Float] Price per share
  # @param date [Date] Date of trade
  # @return [Trade] The executed trade
  def buy(ticker, shares:, price:, date: Date.today)
    raise BadParameterError, "Shares must be positive" if shares <= 0
    raise BadParameterError, "Price must be positive" if price <= 0

    total_cost = shares * price
    commission = calculate_commission(total_cost)
    total_with_commission = total_cost + commission

    raise "Insufficient funds: need #{total_with_commission}, have #{@cash}" if total_with_commission > @cash

    # Update or create position
    if @positions[ticker]
      pos = @positions[ticker]
      total_shares = pos.shares + shares
      total_cost_basis = pos.total_cost + total_cost
      pos.shares = total_shares
      pos.avg_cost = total_cost_basis / total_shares
      pos.total_cost = total_cost_basis
    else
      @positions[ticker] = Position.new(
        ticker,
        shares,
        price,
        total_cost
      )
    end

    # Deduct cash
    @cash -= total_with_commission

    # Record trade
    trade = Trade.new(ticker, :buy, shares, price, date, total_cost, commission)
    @trades << trade

    trade
  end

  # Sell shares of a stock
  # @param ticker [String] Stock ticker symbol
  # @param shares [Integer] Number of shares to sell
  # @param price [Float] Price per share
  # @param date [Date] Date of trade
  # @return [Trade] The executed trade
  def sell(ticker, shares:, price:, date: Date.today)
    raise BadParameterError, "Shares must be positive" if shares <= 0
    raise BadParameterError, "Price must be positive" if price <= 0
    raise "No position in #{ticker}" unless @positions[ticker]

    pos = @positions[ticker]
    raise "Insufficient shares: trying to sell #{shares}, have #{pos.shares}" if shares > pos.shares

    total_sale = shares * price
    commission = calculate_commission(total_sale)
    net_proceeds = total_sale - commission

    # Update position
    if shares == pos.shares
      # Selling entire position
      @positions.delete(ticker)
    else
      # Partial sale - reduce shares and total cost proportionally
      cost_per_share = pos.total_cost / pos.shares
      pos.shares -= shares
      pos.total_cost -= (cost_per_share * shares)
      # avg_cost stays the same
    end

    # Add cash
    @cash += net_proceeds

    # Record trade
    trade = Trade.new(ticker, :sell, shares, price, date, total_sale, commission)
    @trades << trade

    trade
  end

  # Get current position for a ticker
  # @param ticker [String] Stock ticker symbol
  # @return [Position, nil] The position or nil if not found
  def position(ticker)
    @positions[ticker]
  end

  # Get all current positions
  # @return [Hash] Hash of ticker => Position
  def all_positions
    @positions
  end

  # Calculate total portfolio value
  # @param current_prices [Hash] Hash of ticker => current_price
  # @return [Float] Total portfolio value (cash + positions)
  def value(current_prices = {})
    positions_value = @positions.sum do |ticker, pos|
      current_price = current_prices[ticker] || pos.avg_cost
      pos.value(current_price)
    end

    @cash + positions_value
  end

  # Calculate total profit/loss across all positions
  # @param current_prices [Hash] Hash of ticker => current_price
  # @return [Float] Total P&L
  def profit_loss(current_prices = {})
    value(current_prices) - @initial_cash
  end

  # Calculate profit/loss percentage
  # @param current_prices [Hash] Hash of ticker => current_price
  # @return [Float] P&L percentage
  def profit_loss_percent(current_prices = {})
    return 0.0 if @initial_cash.zero?
    (profit_loss(current_prices) / @initial_cash) * 100.0
  end

  # Calculate total return (including dividends if tracked)
  # @param current_prices [Hash] Hash of ticker => current_price
  # @return [Float] Total return as decimal (e.g., 0.15 for 15%)
  def total_return(current_prices = {})
    return 0.0 if @initial_cash.zero?
    profit_loss(current_prices) / @initial_cash
  end

  # Get trade history
  # @return [Array<Trade>] Array of all trades
  def trade_history
    @trades
  end

  # Get summary statistics
  # @param current_prices [Hash] Hash of ticker => current_price
  # @return [Hash] Summary statistics
  def summary(current_prices = {})
    {
      initial_cash: @initial_cash,
      current_cash: @cash,
      positions_count: @positions.size,
      total_value: value(current_prices),
      profit_loss: profit_loss(current_prices),
      profit_loss_percent: profit_loss_percent(current_prices),
      total_return: total_return(current_prices),
      total_trades: @trades.size,
      buy_trades: @trades.count { |t| t.action == :buy },
      sell_trades: @trades.count { |t| t.action == :sell }
    }
  end

  # Save portfolio to CSV file
  # @param filename [String] Path to CSV file
  def save_to_csv(filename)
    CSV.open(filename, 'wb') do |csv|
      csv << ['ticker', 'shares', 'avg_cost', 'total_cost']
      @positions.each do |ticker, pos|
        csv << [ticker, pos.shares, pos.avg_cost, pos.total_cost]
      end
    end
  end

  # Save trade history to CSV file
  # @param filename [String] Path to CSV file
  def save_trades_to_csv(filename)
    CSV.open(filename, 'wb') do |csv|
      csv << ['date', 'ticker', 'action', 'shares', 'price', 'total', 'commission']
      @trades.each do |trade|
        csv << [
          trade.date,
          trade.ticker,
          trade.action,
          trade.shares,
          trade.price,
          trade.total,
          trade.commission
        ]
      end
    end
  end

  # Load portfolio from CSV file
  # @param filename [String] Path to CSV file
  def self.load_from_csv(filename)
    portfolio = new(initial_cash: 0)

    CSV.foreach(filename, headers: true) do |row|
      ticker = row['ticker']
      shares = row['shares'].to_i
      avg_cost = row['avg_cost'].to_f
      total_cost = row['total_cost'].to_f

      portfolio.positions[ticker] = Position.new(
        ticker,
        shares,
        avg_cost,
        total_cost
      )
    end

    portfolio
  end

  private

  # Calculate commission for a trade
  # @param total [Float] Total trade value
  # @return [Float] Commission amount
  def calculate_commission(total)
    # Simple flat commission model
    @commission
  end
end
