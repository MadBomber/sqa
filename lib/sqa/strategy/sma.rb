# lib/sqa/strategy/sma.rb
# frozen_string_literal: true

require_relative 'common'

class SQA::Strategy::SMA
  extend SQA::Strategy::Common

  PERIOD = 20

  # Trade the trend around a 20-period SMA.
  #
  # Accepts two vector shapes:
  #   * legacy pre-classified hash: vector.sma = { trend: :up | :down }
  #     (previously this read vector.rsi by mistake — fixed)
  #   * numeric: vector.sma is the latest SMA value (Stream) — otherwise the
  #     SMA is computed from vector.prices. Price above its SMA is an uptrend
  #     (buy); below is a downtrend (sell).
  def self.trade(vector)
    raw = vector.respond_to?(:sma) ? vector.sma : nil

    if raw.is_a?(Hash)
      return :buy  if raw[:trend] == :up
      return :sell if raw[:trend] == :down

      return :hold
    end

    prices = vector.respond_to?(:prices) ? vector.prices : nil
    return :hold unless prices && prices.size >= PERIOD

    sma   = latest(raw) || latest(SQAI.sma(prices, period: PERIOD))
    price = prices.last
    return :hold if sma.nil? || price.nil?

    if    price > sma then :buy
    elsif price < sma then :sell
    else  :hold
    end
  end
end
