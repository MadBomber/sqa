# lib/sqa/indicators/identify_wave_condition.rb

module SQA::Indicators

  # @param prices [Array] An array of historical prices.
  # @param wave_length [Integer] The expected length of a wave pattern.
  # @param tolerance [Float]  The tolerance level for considering a price movement
  #                           as part of a wave.
  # @return [Boolean] True if a wave condition is identified, false otherwise.
  #
  def identify_wave_condition?(prices, wave_length, tolerance)
    return false if prices.length < wave_length

    wave_start = 0
    wave_end = wave_length - 1

    while wave_end < prices.length
      wave = prices[wave_start..wave_end]

      if wave.length == wave_length && wave_pattern?(wave, tolerance)
        return true
      end

      wave_start += 1
      wave_end += 1
    end

    false
  end


  # @param wave [Array] An array representing a wave pattern.
  # @param tolerance [Float]  The tolerance level for considering a price movement
  #                           as part of a wave.
  # @return [Boolean] True if the wave pattern satisfies the wave condition,
  #                   false otherwise.
  #
  def wave_pattern?(wave, tolerance)
    wave.each_cons(2) do |a, b|
      return false if (b - a).abs > tolerance
    end

    true
  end

end

