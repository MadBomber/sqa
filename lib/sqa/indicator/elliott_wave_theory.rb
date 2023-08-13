# lib/sqa/indicator/elliott_wave_theory.rb

# TIDI: This is very simplistic.  It may be completely wrong even
#       as simplistic as it is.  Consider using the sma_trend to
#       acquire the up and down patterns.  Run those through a
#       classifier.  Might even have to review the concept of a
#       trend with regard to varying the periods to turn
#       many small patterns into fewer larger patterns.  Then
#       maybe the 12345 and abc patterns will be extractable.
#       On the whole I think the consensus is that EWT is not
#       that useful for predictive trading.

class SQA::Indicator; class << self

  def elliott_wave_theory(
        prices       # Array of prices
      )
    waves       = []
    wave_start  = 0

    (1..prices.length-2).each do |x|
      turning_point = prices[x] > prices[x-1] && prices[x] > prices[x+1] ||
                      prices[x] < prices[x-1] && prices[x] < prices[x+1]

      if turning_point
        waves << prices[wave_start..x]
        wave_start = x + 1
      end
    end

    analysis = []

    waves.each do |wave|
      analysis << {
        wave:     wave,
        oattern:  ewt_identify_pattern(wave)
      }
    end

    analysis
  end


  private def ewt_identify_pattern(wave)
    if wave.length == 5
      :impulse
    elsif wave.length == 3
      :corrective_zigzag
    elsif wave.length > 5
      :corrective_complex
    else
      :unknown
    end
  end

end; end

