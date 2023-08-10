# lib/sqa/indicators/classify_market_profile.rb

module SQA::Indicators

  #######################################################################
  # Classifies the market profile based on trading volume and price levels.
  #
  # Market Profile Analysis: Market profile analysis involves studying the
  # distribution of trading volume and price levels over time. It helps
  # identify areas of support and resistance and provides insights into market
  # sentiment.
  #
  # @param volume [Array] An array of trading volume data.
  # @param prices [Array] An array of price levels.
  # @param support_threshold [Float]  The threshold for considering a price level
  #                                   as support.
  # @param resistance_threshold [Float] The threshold for considering a price
  #                                     level as resistance.
  # @return [String] The classification of the market profile.
  #
  def classify_market_profile(volume, prices, support_threshold, resistance_threshold)
    return "Insufficient data" if volume.empty? || prices.empty?

    total_volume    = volume.sum
    average_volume  = total_volume / volume.length.to_f
    max_volume      = volume.max

    support_levels    = prices.select { |price| price <= support_threshold }
    resistance_levels = prices.select { |price| price >= resistance_threshold }

    if support_levels.empty? && resistance_levels.empty?
      return "Neutral"
    elsif support_levels.empty?
      return "Resistance"
    elsif resistance_levels.empty?
      return "Support"
    else
      return "Mixed"
    end
  end

end

