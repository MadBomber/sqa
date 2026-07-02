# lib/sqa/strategy/ema.rb
# frozen_string_literal: true

require_relative 'common'

class SQA::Strategy::EMA
  extend SQA::Strategy::Common

  PERIOD = 20

  # Trade the trend around a 20-period EMA.
  #
  # Accepts two vector shapes:
  #   * legacy pre-classified hash: vector.ema = { trend: :up | :down }
  #   * numeric: vector.ema is the latest EMA value (Stream) — otherwise the
  #     EMA is computed from vector.prices. Price above its EMA is an uptrend
  #     (buy); below is a downtrend (sell).
  def self.trade(vector)
    raw = vector.respond_to?(:ema) ? vector.ema : nil

    if raw.is_a?(Hash)
      return :buy  if raw[:trend] == :up
      return :sell if raw[:trend] == :down

      return :hold
    end

    prices = vector.respond_to?(:prices) ? vector.prices : nil
    return :hold unless prices && prices.size >= PERIOD

    ema   = latest(raw) || latest(SQAI.ema(prices, period: PERIOD))
    price = prices.last
    return :hold if ema.nil? || price.nil?

    if    price > ema then :buy
    elsif price < ema then :sell
    else  :hold
    end
  end
end
