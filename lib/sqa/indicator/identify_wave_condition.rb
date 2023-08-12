# lib/sqa/indicator/identify_wave_condition.rb

class SQA::Indicator; class << self

  def identify_wave_condition?(
        prices,       # Array of prices
        wave_length,  # Integer expected length of a wave pattern
        tolerance     # Float delta change in price that would indicate a wave
      )
    return false if prices.length < wave_length

    wave_start  = 0
    wave_end    = wave_length - 1

    while wave_end < prices.length
      wave = prices[wave_start..wave_end]

      if  wave.length == wave_length    &&
          wave_pattern?(wave, tolerance)
        return true
      end

      wave_start  += 1
      wave_end    += 1
    end

    false
  end


  private def wave_pattern?(wave, tolerance)
    wave.each_cons(2) do |a, b|
      return false if (b - a).abs > tolerance
    end

    true
  end

end; end

