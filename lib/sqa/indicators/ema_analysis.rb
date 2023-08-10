# lib/sqa/indicators/ema_analysis.rb

module SQA::Indicators

  ##############################################################################
  # Calculates the Exponential Moving Average (EMA) and performs basic analysis.
  #
  # In financial analysis, the Exponential Moving Average (EMA) is a commonly used
  # technical indicator that helps identify trends and smooth out price data. It is
  # a type of moving average that gives more weight to recent prices, making it more
  #  responsive to recent price changes compared to other moving averages.
  #
  # The EMA is calculated by applying a smoothing factor (often represented as a
  # percentage) to the previous EMA value and adding a weighted average of the
  # current price. The smoothing factor determines the weight given to the most
  # recent price data, with higher values giving more weight to recent prices.
  #
  # The EMA is used for various purposes in financial analysis, including:
  #
  # 1. Trend Identification: The EMA is often used to identify the direction and
  # strength of a trend. When the current price is above the EMA, it suggests an
  # uptrend, while a price below the EMA suggests a downtrend. Traders and
  # investors may use the EMA crossover (when the price crosses above or below
  # the EMA) as a signal to enter or exit positions.
  #
  # 2. Support and Resistance Levels: The EMA can act as dynamic support or
  # resistance levels. In an uptrend, the EMA may provide support, and in a
  # downtrend, it may act as resistance. Traders may use the EMA as a reference
  # point for setting stop-loss orders or profit targets.
  #
  # 3. Price Reversals: The EMA can help identify potential price reversals. When
  # the price deviates significantly from the EMA, it may indicate an overbought
  # or oversold condition, suggesting a potential reversal in the near future.
  # Traders may use this information to anticipate price reversals and adjust
  # their trading strategies accordingly.
  #
  # 4. Volatility Assessment: The EMA can be used to assess market volatility.
  # When the EMA is relatively flat, it suggests low volatility, while a steeply
  # sloping EMA indicates higher volatility. Traders may adjust their trading
  # strategies based on the level of volatility indicated by the EMA.
  #
  # It's important to note that the EMA is just one of many technical indicators
  # used in financial analysis. It is often used in combination with other
  # indicators, such as the Simple Moving Average (SMA), to gain a more
  # comprehensive understanding of market trends and price movements.
  #
  # Traders and investors should consider their own trading strategies, risk
  # tolerance, and timeframes when using the EMA or any other technical indicator
  # for financial analysis. It's also recommended to backtest and validate any
  # trading strategies before applying them in real-time trading.
  #
  #
  # @param prices [Array] An array of historical prices.
  # @param period [Integer] The number of periods to consider for calculating
  #                         the EMA.
  # @return [Hash] A hash containing the EMA values and analysis results.
  #
  def ema_analysis(prices, period)
    return {} if prices.empty? || period <= 0

    ema_values = []
    ema_values << prices.first

    multiplier = (2.0 / (period + 1))

    (1...prices.length).each do |i|
      ema = (prices[i] - ema_values.last) * multiplier + ema_values.last
      ema_values << ema.round(2)
    end

    analysis = {}

    analysis[:ema_values] = ema_values
    analysis[:trend]      = determine_trend(ema_values)
    analysis[:support]    = determine_support(ema_values)
    analysis[:resistance] = determine_resistance(ema_values)

    analysis
  end

  # Determines the trend based on the EMA values.
  #
  # @param ema_values [Array] An array of EMA values.
  # @return [Symbol] The trend: :up, :down, or :sideways.
  #
  def determine_trend(ema_values)
    return :sideways if ema_values.empty?

    last_ema      = ema_values.last
    previous_ema  = ema_values[-2]

    if last_ema > previous_ema
      :up
    elsif last_ema < previous_ema
      :down
    else
      :sideways
    end
  end

  # Determines the support level based on the EMA values.
  #
  # @param ema_values [Array] An array of EMA values.
  # @return [Float] The support level.
  #
  def determine_support(ema_values)
    return 0.0 if ema_values.empty?

    ema_values.min
  end

  # Determines the resistance level based on the EMA values.
  #
  # @param ema_values [Array] An array of EMA values.
  # @return [Float] The resistance level.
  def determine_resistance(ema_values)
    return 0.0 if ema_values.empty?

    ema_values.max
  end

end

