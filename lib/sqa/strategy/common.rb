# lib/sqa/strategry/common.rb

# This module needs to be extend'ed within
# a strategy class so that these common class
# methods are available in every trading strategy.

class SQA::Strategy
  module Common
    # Reduce a raw indicator value to a single Float so strategies work whether
    # they are handed the latest value (Backtest) or the full series (Stream).
    # Returns nil for anything non-numeric (e.g. a legacy { trend: } hash).
    def latest(raw)
      case raw
      when Numeric then raw
      when Array   then raw.compact.last
      end
    end

    # Shared trend-following logic for moving-average strategies (SMA/EMA).
    #
    # Accepts two vector shapes via +raw+ (the strategy's indicator value read
    # off the vector):
    #   * legacy pre-classified hash: { trend: :up | :down }
    #   * numeric latest value or full series; otherwise the moving average is
    #     computed from +prices+ via the given block. Price above its moving
    #     average is an uptrend (buy); below is a downtrend (sell).
    #
    # @param raw [Hash, Numeric, Array, nil] indicator value off the vector
    # @param prices [Array<Numeric>, nil] price history
    # @param period [Integer] moving-average period
    # @yieldparam prices [Array<Numeric>] price history
    # @yieldparam period [Integer] moving-average period
    # @yieldreturn [Array<Numeric>] the moving-average series
    # @return [Symbol] :buy, :sell, or :hold
    def moving_average_trade(raw, prices, period)
      if raw.is_a?(Hash)
        return :buy  if raw[:trend] == :up
        return :sell if raw[:trend] == :down

        return :hold
      end

      return :hold unless prices && prices.size >= period

      average = latest(raw) || latest(yield(prices, period))
      price   = prices.last
      return :hold if average.nil? || price.nil?

      if    price > average then :buy
      elsif price < average then :sell
      else  :hold
      end
    end

    def trade_against(vector)
      return :hold unless respond_to? :trade

      recommendation = trade(vector)

      if recommendation == :sell
        :buy
      elsif recommendation == :buy
        :sell
      else
        :hold
      end
    end

    def desc
      doc_filename 	= name.split('::').last.downcase + ".md"
      doc_path 			= Pathname.new(__dir__) + doc_filename

      doc = if doc_path.exist?
              doc_path.read
            else
              "A description of #{name} is not available"
            end

      puts doc
    end
  end
end
