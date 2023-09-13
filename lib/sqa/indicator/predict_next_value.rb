# lib/sqa/indicator/predict_next_values.rb

module SQA
end

class SQA::Indicator; class << self

  def predict_next_values(array, predictions)
    result = []

    array.each_cons(2) do |a, b|
      # TODO: take 3 at a time. compare 3rd
      #       prediction. Generate an average delta
      #       between predicted and actual.  Return
      #       the prediction as a range???
      result << b + (b - a)
    end

    if predictions > 0
      (1..predictions).each do |_|
        last_two_values = result.last(2)
        delta           = last_two_values.last - last_two_values.first
        next_value      = last_two_values.last + delta
        result         << next_value
      end
    end

    result.last(predictions)
  end
  alias_method :pnv, :predict_next_values


  # Returns a forecast for future values based on the near past
  #
  # When I wrote this I was thinking of hurricane forecasting and how
  # the cone of probability gets larger the further into the future
  # the forecast goes.  This does not produce that kind of probability
  # cone; but, that was hwat I was thinking about
  #
  # array is an Array - for example historical price data
  # predictions is an Integer for how many predictions into the future
  #
  def pnv2(array, predictions)
    result    = []
    last_inx  = array.size - 1 # indexes are zero based

    predictions.times do |x|
      x += 1 # forecasting 1 day into the future needs 2 days of near past data

      # window is the near past values
      window  = array[last_inx-x..]

      high      = window.max
      low       = window.min
      midpoint  = (high + low) / 2.0

      result << [high, midpoint, low]
    end

    result
  end


  def pnv3(prices, prediction_window)
    predicted_prices  = []
    known             = prices.last(prediction_window+2).dup

    # Loop through the prediction window size
    (1..prediction_window).each do |x|
      current_price = known.last

      # Calculate the percentage change between the current price and its previous price
      percentage_change = (current_price - known[-1]) / known[-1] # .to_f

      # Calculate the predicted price based on the percentage change
      predicted_price = current_price + (current_price * percentage_change)
      predicted_prices.unshift(predicted_price)

      # Update the prices array for the next iteration
      known.pop
    end

    predicted_prices
  end



end; end
