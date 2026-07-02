# lib/sqa/strategry/ema.rb

require_relative 'common'

class SQA::Strategy::EMA
  extend SQA::Strategy::Common

  def self.trade(vector)
    ema_trend = vector.ema[:trend]

    if ema_trend == :up
      :buy
    elsif ema_trend == :down
      :sell
    else
      :hold
    end
  end
end
