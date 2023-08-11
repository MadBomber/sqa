# lib/sqa/indicators/macd.rb

module SQA::Indicators

  def moving_average_convergence_divergence(
        data,
        short_period,
        long_period,
        signal_period
      )

    short_ma    = simple_moving_average(data, short_period)
    long_ma     = simple_moving_average(data, long_period)
    macd_line   = short_ma.last - long_ma.last
    signal_line = simple_moving_average(short_ma, signal_period).last

    return [macd_line, signal_line]
  end
  alias_method :macd, :moving_average_convergence_divergence

end

