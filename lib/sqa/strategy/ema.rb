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
    raw    = vector.respond_to?(:ema) ? vector.ema : nil
    prices = vector.respond_to?(:prices) ? vector.prices : nil

    moving_average_trade(raw, prices, PERIOD) { |p, period| SQAI.ema(p, period: period) }
  end
end
