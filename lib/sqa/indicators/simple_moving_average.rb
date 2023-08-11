# lib/sqa/indicators/simple_moving_average.rb

module SQA::Indicators

  def simple_moving_average(data, period)
    if data.first.is_a? Hash
      prices = data.map{|r| r['Adj Close'].to_f}
    else
      prices = data
    end

    moving_averages = []
    prices.each_cons(period) do |window|
      moving_average = window.sum / period.to_f
      moving_averages << moving_average
    end
    return moving_averages
  end
  alias_method :sma, :simple_moving_average

end

