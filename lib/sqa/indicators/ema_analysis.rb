# lib/sqa/indicators/ema_analysis.rb

module SQA::Indicators

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


  # @param ema_values [Array] An array of EMA values.
  # @return [Float] The support level.
  #
  def determine_support(ema_values)
    return 0.0 if ema_values.empty?

    ema_values.min
  end


  # @param ema_values [Array] An array of EMA values.
  # @return [Float] The resistance level.
  def determine_resistance(ema_values)
    return 0.0 if ema_values.empty?

    ema_values.max
  end

end

