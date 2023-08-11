# lib/sqa/indicators/rsi.rb

module SQA::Indicators

  def rsi(data, period)
    prices  = data.map{|r| r['Adj Close'].to_f}
    gains   = []
    losses  = []

    prices.each_cons(2) do |pair|
      change = pair[1] - pair[0]
      if change > 0
        gains   << change
        losses  << 0
      else
        gains   << 0
        losses  << -change
      end
    end

    avg_gain  = gains.first(period).sum / period.to_f
    avg_loss  = losses.first(period).sum / period.to_f
    rs        = avg_gain / avg_loss
    rsi       = 100 - (100 / (1 + rs))

    meaning = ""
    if rsi >= 70.0
      meaning = "Over Bought"
    elsif rsi <= 30.0
      meaning = "Over Sold"
    end

    return {rsi: rsi, meaning: meaning}
  end

end

