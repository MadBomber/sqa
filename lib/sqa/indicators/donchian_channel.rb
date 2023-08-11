# lib/sqa/indicators/donchian_channel.rb

module SQA::Indicators

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

