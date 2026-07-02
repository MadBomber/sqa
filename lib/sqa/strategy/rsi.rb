# lib/sqa/strategry/rsi.rb

require_relative 'common'

class SQA::Strategy::RSI
  extend SQA::Strategy::Common

  def self.trade(vector)
    rsi_trend = vector.rsi[:trend]

    if rsi_trend == :over_bought
      :sell
    elsif rsi_trend == :over_sold
      :buy
    else
      :hold
    end
  end
end
