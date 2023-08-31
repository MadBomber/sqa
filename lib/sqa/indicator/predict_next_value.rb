# lib/sqa/indicator/predict_next_values.rb

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

end; end
