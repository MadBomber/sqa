# fin_tech/lib/fin_tech/macd.rb

module FinTech

  #######################################################################
  # Moving Average Convergence Divergence (MACD)
  #
  #
  # The MACD is a trend-following momentum indicator that measures the
  # relationship between two moving averages over a specified time period. The
  # MACD is calculated by subtracting the long-term moving average from the
  # short-term moving average.
  #
  # The method takes in an array of historical prices for a stock, a short period
  # (the number of days to calculate the short-term moving average over), a long
  # period (the number of days to calculate the long-term moving average over),
  # and a signal period (the number of days to calculate the signal line moving
  # average over).
  #
  # The method first calculates the short-term moving average by calling the
  # `moving_averages` method with the `prices` array and the `short_period`
  # parameter. It then calculates the long-term moving average by calling the
  # `moving_averages` method with the `prices` array and the `long_period`
  # parameter.
  #
  # Next, the method calculates the MACD line by subtracting the long-term moving
  # average from the short-term moving average. This is done by taking the last
  # element of the `short_ma` array (which contains the short-term moving
  # averages for each window) and subtracting the last element of the `long_ma`
  # array (which contains the long-term moving averages for each window).
  #
  # Finally, the method calculates the signal line by taking the moving average of
  # the MACD line over the specified `signal_period`. This is done by calling the
  # `moving_averages` method with the `short_ma` array and the `signal_period`
  # parameter, and taking the last element of the resulting array.
  #
  # The method returns an array containing the MACD line and the signal line.
  #
  # Note that this is just a basic implementation of the MACD indicator, and there
  # are many variations and refinements that can be made depending on the
  # specific requirements of your program.
  #
  # The Moving Average Convergence Divergence (MACD) is a technical analysis
  # indicator that is used to identify changes in momentum, direction, and trend
  # for a security. The MACD is calculated by subtracting the 26-period
  # exponential moving average (EMA) from the 12-period EMA.
  #
  # The values 1.8231937142857078 and 164.44427957142855 that you provided are
  # likely the MACD line and the signal line, respectively. The MACD line is the
  # difference between the 12-period EMA and the 26-period EMA, while the signal
  # line is a 9-period EMA of the MACD line.
  #
  # The MACD line crossing above the signal line is often considered a bullish
  # signal, while the MACD line crossing below the signal line is often
  # considered a bearish signal. The distance between the MACD line and the
  # signal line can also provide insight into the strength of the trend.
  #
  # Without additional context, it's difficult to interpret the specific values of
  # 1.8231937142857078 and 164.44427957142855 for the MACD and signal lines of a
  # stock. However, in general, the MACD can be used to identify potential buy
  # and sell signals for a security, as well as to provide insight into the
  # strength of the trend.

  def macd(data, short_period, long_period, signal_period)
    short_ma    = simple_moving_average(data, short_period)
    long_ma     = simple_moving_average(data, long_period)
    macd_line   = short_ma.last - long_ma.last
    signal_line = simple_moving_average(short_ma, signal_period).last

    return [macd_line, signal_line]
  end

end

