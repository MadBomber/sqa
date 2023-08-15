
class SQA::Indicator; class << self

  def peaks_and_valleys(
        prices,   # Array of prices
        delta     # Integer distance delta (# of higher or lower prices to either side)
      )
    peaks   = []
    valleys = []
    period  = 2 * delta + 1

    prices.each_cons(period) do |window|
      price    = window[delta]

      next if window.count(price) == period

      peaks   << price if window.max == price
      valleys << price if window.min == price
    end

    {
      period:   period,
      peaks:    peaks,
      valleys:  valleys
    }
  end
  alias_method :pav, :peaks_and_valleys

end; end
