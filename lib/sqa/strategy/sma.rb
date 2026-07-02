# lib/sqa/strategry/sma.rb

require_relative 'common'

class SQA::Strategy::SMA
  extend SQA::Strategy::Common

  def self.trade(vector)
    sma_trend = vector.rsi[:trend]

    if sma_trend == :up
      :buy
    elsif sma_trend == :down
      :sell
    else
      :hold
    end
  end
end
