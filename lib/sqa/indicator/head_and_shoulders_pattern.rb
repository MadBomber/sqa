# lib/sqa/indicator/head_and_shoulders_pattern.rb

module SQA::Indicator; class << self


  def head_and_shoulders_pattern?(
        prices  # Array of prices
      )

    return false if prices.length < 5

    data            = prices.last(5)

    left_shoulder   = data[0]
    head            = data[1]
    right_shoulder  = data[2]
    neckline        = data[3]
    right_peak      = data[4]

    head        > left_shoulder   &&
    head        > right_shoulder  &&
    right_peak  < neckline
  end

end; end

