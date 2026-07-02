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
