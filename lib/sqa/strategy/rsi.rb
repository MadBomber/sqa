# lib/sqa/strategy/rsi.rb
# frozen_string_literal: true

require_relative 'common'

class SQA::Strategy::RSI
  extend SQA::Strategy::Common

  OVERSOLD   = 30
  OVERBOUGHT = 70

  # Buy when oversold, sell when overbought.
  #
  # Accepts two vector shapes:
  #   * legacy pre-classified hash: vector.rsi = { trend: :over_sold | :over_bought }
  #   * numeric: vector.rsi is the latest RSI value (Backtest) or the RSI series
  #     (Stream); falls back to computing RSI(14) from vector.prices.
  def self.trade(vector)
    raw = vector.respond_to?(:rsi) ? vector.rsi : nil

    if raw.is_a?(Hash)
      return :buy  if raw[:trend] == :over_sold
      return :sell if raw[:trend] == :over_bought

      return :hold
    end

    rsi = latest(raw) || rsi_from_prices(vector)
    return :hold if rsi.nil?

    if    rsi <= OVERSOLD   then :buy
    elsif rsi >= OVERBOUGHT then :sell
    else  :hold
    end
  end

  # RSI(14) from the vector's price history, or nil if there isn't enough data.
  def self.rsi_from_prices(vector)
    prices = vector.respond_to?(:prices) ? vector.prices : nil
    return nil unless prices && prices.size >= 15

    latest(SQAI.rsi(prices, period: 14))
  end
end
