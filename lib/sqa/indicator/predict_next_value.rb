# lib/sqa/indicator/predict_next_values.rb

module SQA
end

class SQA::Indicator; class << self

  # Produce a Table show actual values and forecasted values
  #
  # actual .... Array of Float
  # forecast .. Array of Float or Array of Array of Float
  #             entry is either a single value or
  #             an Array [high, guess, low]
  #
  def prediction_test(actual, forecast)

    unless actual.size == forecast.size
      debug_me("== ERROR =="){[
        "actual.size",
        "forecast.size"
      ]}
    end

    # Method Under Test (MUT)
    mut     = caller[0][/`([^']*)'/, 1]
    window  = actual.size
    hgl     = forecast.first.is_a?(Array)

    if hgl
      headers = %w[ Actual Forecast Diff %off InRange? High Low ]
    else
      headers = %w[ Actual Forecast Diff %off ]
    end

    diff    = []
    percent = []
    values  = []

    actual.map!{|v| v.round(3)}

    if hgl
      high  = forecast.map{|v| v[0].round(3)}
      guess = forecast.map{|v| v[1].round(3)}
      low   = forecast.map{|v| v[2].round(3)}
    else
      guess = forecast.map{|v| v.round(3)}
    end

    window.times do |x|
      diff    << (actual[x] - guess[x]).round(3)
      percent << ((diff.last / guess[x])*100.0).round(3)

      entry = [
        actual[x], guess[x],
        diff[x], percent[x],
      ]

      if hgl
        entry << ( (high[x] >= actual[x] && actual[x] >= low[x]) ? "Yes" : "" )
        entry << high[x]
        entry << low[x]
      end

      values << entry
    end

    the_table = TTY::Table.new(headers, values)

    puts "\n#{mut} Result Validation"

    puts  the_table.render(
            :unicode,
            {
              padding:    [0, 0, 0, 0],
              alignments:  [:right]*values.first.size,
            }
          )
    puts
  end


  def predict_next_values(stock, window, testing=false)
    prices  = stock.df.adj_close_price.to_a
    known   = prices.pop(window) if testing
    result  = []

    prices.each_cons(2) do |a, b|
      result << b + (b - a)
    end

    if window > 0
      (1..window).each do |_|
        last_two_values = result.last(2)
        delta           = last_two_values.last - last_two_values.first
        next_value      = last_two_values.last + delta
        result         << next_value
      end
    end

    prediction_test(known, result.last(window)) if testing

    result.last(window)
  end
  alias_method :pnv, :predict_next_values


  def pnv2(stock, window, testing=false)
    prices  = stock.df.adj_close_price.to_a
    known   = prices.pop(window) if testing

    result    = []
    last_inx  = prices.size - 1 # indexes are zero based

    window.times do |x|
      x += 1 # forecasting 1 day into the future needs 2 days of near past data

      # window is the near past values
      window  = prices[last_inx-x..]

      high      = window.max
      low       = window.min
      midpoint  = (high + low) / 2.0

      result   << [high, midpoint, low]
    end

    prediction_test(known, result) if testing

    result
  end


  def pnv3(stock, window, testing=false)
    prices  = stock.df.adj_close_price.to_a
    known   = prices.pop(window) if testing

    result  = []
    known   = prices.last(window)

    last_inx = prices.size - 1

    (0..window-1).to_a.reverse.each do |x|
      curr_inx          = last_inx - x
      prev_inx          = curr_inx - 1
      current_price     = prices[curr_inx]
      percentage_change = (current_price - prices[prev_inx]) / prices[prev_inx]

      result << current_price + (current_price * percentage_change)
    end

    prediction_test(known, result) if testing

    result
  end


  def pnv4(stock, window, testing=false)
    prices  = stock.df.adj_close_price.to_a
    known   = prices.pop(window) if testing

    result        = []
    known         = prices.last(window).dup
    current_price = known.last

    # Loop through the prediction window size
    (1..window).each do |x|

      # Calculate the percentage change between the current price and its previous price
      percentage_change = (current_price - prices[-x]) / prices[-x]

      result << current_price + (current_price * percentage_change)
    end

    prediction_test(known, result) if testing

    result
  end


  def pnv5(stock, window, testing=false)
    prices  = stock.df.adj_close_price.to_a
    known   = prices.pop(window) if testing

    result            = []
    current_price     = prices.last

    rate              = 0.9 # convert angle into percentage
    sma_trend         = stock.indicators.sma_trend
    percentage_change = 1 + (sma_trend[:angle] / 100.0) * rate

    # Assumes the SMA trend will continue
    window.times do |_|
      result       << current_price * percentage_change
      current_price = result.last
    end

    prediction_test(known, result) if testing

    result
  end

end; end
