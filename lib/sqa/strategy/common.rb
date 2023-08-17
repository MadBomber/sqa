# lib/sqa/strategry/common.rb

# This module needs to be extend'ed within
# a strategy class so that these common class
# methods are available in every trading strategy.

class SQA::Strategy
	module Common
		def trade_against(vector)
			recommendation = trade(vector)

			if :sell == recommendation
				:buy
			elsif :buy == recommendation
				:sell
			else
				:hold
			end
		end

		def desc
			doc_path = Pathname.new __FILE__.gsub('.rb', '.md')

			if doc_path.exist?
				doc = doc_path.read
			else
				doc = "A description of #{self.name} is not available"
			end

			puts doc
		end
	end
end
