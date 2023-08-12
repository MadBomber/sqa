# lib/sqa/indicator/candlestick_pattern_recognizer.rb

module SQA::Indicator; class << self

  def candlestick_pattern_recognizer(
        open_prices,  # Array day's ppen price
        high_prices,  # Array day's high price
        low_prices,   # Array day's low price
        close_prices  # Array day's closing price
      )
    patterns = []

    close_prices.each_with_index do |close, index|
      if index >= 2
        previous_close  = close_prices[index  - 1]
        previous_open   = open_prices[index   - 1]
        previous_high   = high_prices[index   - 1]
        previous_low    = low_prices[index    - 1]

        second_previous_close = close_prices[index  - 2]
        second_previous_open  = open_prices[index   - 2]
        second_previous_high  = high_prices[index   - 2]
        second_previous_low   = low_prices[index    - 2]

        if  close           > previous_close  &&
            previous_close  < previous_open   &&
            close           < previous_open   &&
            close           > previous_low    &&
            close           > second_previous_close
          patterns << :bullish_engulfing

        elsif close           < previous_close  &&
              previous_close  > previous_open   &&
              close           > previous_open   &&
              close           < previous_high   &&
              close           < second_previous_close
          patterns << :bearish_engulfing

        elsif close           > previous_close  &&
              previous_close  < previous_open   &&
              close           < previous_open   &&
              close           < previous_low    &&
              close           < second_previous_close
          patterns << :bearish_harami

        elsif close           < previous_close  &&
              previous_close  > previous_open   &&
              close           > previous_open   &&
              close           > previous_high   &&
              close           > second_previous_close
          patterns << :bullish_harami
        end
      end
    end

    patterns
  end

end; end

