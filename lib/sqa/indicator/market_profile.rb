# lib/sqa/indicator/market_profile.rb

class SQA::Indicator; class << self

  def market_profile(
        volumes,              # Array of volumes
        prices,               # Array of prices
        support_threshold,    # Float stock's support price estimate
        resistance_threshold  # Float stock's resistance price estimate
      )
    total_volume    = volumes.sum
    average_volume  = volumes.mean
    max_volume      = volumes.max

    support_levels    = prices.select { |price| price <= support_threshold }
    resistance_levels = prices.select { |price| price >= resistance_threshold }

    if  support_levels.empty?     &&
        resistance_levels.empty?
      :neutral
    elsif support_levels.empty?
      :resistance
    elsif resistance_levels.empty?
      :support
    else
      :mixed
    end
  end
  alias_method :mp, :market_profile

end; end

