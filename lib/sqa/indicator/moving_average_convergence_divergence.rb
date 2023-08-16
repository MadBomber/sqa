# lib/sqa/indicator/moving_average_convergence_divergence.rb

class SQA::Indicator; class << self

  def moving_average_convergence_divergence(
        prices,
        short_period,
        long_period,
        signal_period
      )

    short_ma    = simple_moving_average(prices, short_period)
    long_ma     = simple_moving_average(prices, long_period)
    signal_line = simple_moving_average(short_ma, signal_period)
    macd_line   = []

    prices.size.times do |x|
      macd_line << short_ma[x] - long_ma[x]
    end

    {
      macd:   macd_line,  # Array
      signal: signal_line # Array
    }
  end
  alias_method :macd, :moving_average_convergence_divergence

end; end

