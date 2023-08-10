# lib/sqa/indicators/candlestick_pattern_recognizer.rb

module SQA::Indicators

  # Recognizes common candlestick chart patterns in the given price data.
  #
  # @param open_prices [Array] An array of opening prices.
  # @param high_prices [Array] An array of high prices.
  # @param low_prices [Array] An array of low prices.
  # @param close_prices [Array] An array of closing prices.
  # @return [Array] An array of recognized candlestick patterns.
  #
  def candlestick_pattern_recognizer(open_prices, high_prices, low_prices, close_prices)
    patterns = []

    close_prices.each_with_index do |close, index|
      if index >= 2
        previous_close = close_prices[index - 1]
        previous_open = open_prices[index - 1]
        previous_high = high_prices[index - 1]
        previous_low = low_prices[index - 1]

        second_previous_close = close_prices[index - 2]
        second_previous_open = open_prices[index - 2]
        second_previous_high = high_prices[index - 2]
        second_previous_low = low_prices[index - 2]

        if close > previous_close && previous_close < previous_open && close < previous_open && close > previous_low && close > second_previous_close
          patterns << "Bullish Engulfing"
        elsif close < previous_close && previous_close > previous_open && close > previous_open && close < previous_high && close < second_previous_close
          patterns << "Bearish Engulfing"
        elsif close > previous_close && previous_close < previous_open && close < previous_open && close < previous_low && close < second_previous_close
          patterns << "Bearish Harami"
        elsif close < previous_close && previous_close > previous_open && close > previous_open && close > previous_high && close > second_previous_close
          patterns << "Bullish Harami"
        end
      end
    end

    patterns
  end

end

