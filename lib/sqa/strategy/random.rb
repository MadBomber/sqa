# lib/sqa/strategry/random.rb

require_relative 'common'

class SQA::Strategy::Random
	extend SQA::Strategy::Common

	def self.trade(vector)
		case rand(9)
		when (0..2)
			:buy
		when (3..5)
			:sell
		else
			:hold
		end
	end
end
