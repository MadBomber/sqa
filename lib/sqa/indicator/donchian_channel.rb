# lib/sqa/indicator/donchian_channel.rb

class SQA::Indicator; class << self

  def donchian_channel(
        prices,   # Array of prices
        period    # Integer number of entries to consider
      )
    max               = -999999999
    min               = 999999999
    donchian_channel  = []

    prices.each_with_index do |value, index|
      value = value.to_f
      max   = value if value > max
      min   = value if value < min

      if index >= period - 1
        donchian_channel << [max, min, (max + min) / 2]
        max = -999999999
        min = 999999999
      end
    end

    donchian_channel
  end

end; end

