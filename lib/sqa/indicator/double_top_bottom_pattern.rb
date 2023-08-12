# lib/sqa/indicator/double_top_bottom_pattern.rb

module SQA::Indicator; class << self

  def double_top_bottom_pattern(
        prices  # Array of prices
      )
    return :no_pattern if prices.length < 5

    data                = prices.last(5)

    first_peak          = data[0]
    valley              = data[1]
    second_peak         = data[2]
    neckline            = data[3]
    confirmation_price  = data[4]

    if  first_peak          < second_peak &&
        valley              > first_peak  &&
        valley              > second_peak &&
        confirmation_price  < neckline
      :double_top
    elsif first_peak          > second_peak &&
          valley              < first_peak  &&
          valley              < second_peak &&
          confirmation_price  > neckline
      :double_bottom
    else
      :no_pattern
    end
  end

end; end

