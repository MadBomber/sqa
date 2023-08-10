# lib/sqa/indicators/donchian_channel.rb

module SQA::Indicators

  #######################################################################
  # Calculates the Donchian Channel for a given period and input data.
  #
  # In the domain of computer programming, a Donchian Channel is a technical
  # analysis indicator used to identify potential breakouts and trend reversals
  # in financial markets. It consists of three lines: the upper channel line,
  # the lower channel line, and the middle line.
  #
  # The upper channel line is calculated by finding the highest high over
  # a specified period of time, while the lower channel line is calculated
  # by finding the lowest low over the same period. The middle line is simply
  # the average of the upper and lower channel lines.
  #
  # @param period [Integer] The period for the Donchian Channel.
  # @param input_data [Array] An array of values.
  # @return [Array] An array of arrays representing the Donchian Channel.
  #
  def donchian_channel(period, input_data)
    max = -999999999
    min = 999999999
    donchian_channel = []

    input_data.each_with_index do |value, index|
      value = value.to_f
      max = value if value > max
      min = value if value < min

      if index >= period - 1
        donchian_channel << [max, min, (max + min) / 2]
        max = -999999999
        min = 999999999
      end
    end

    donchian_channel
  end

end

