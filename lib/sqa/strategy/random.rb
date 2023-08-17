# lib/sqa/strategry/random.rb

require_relative 'common'

class SQA::Strategy::Random
	extend SQA::Strategy::Common

	def self.coin_flip(vector)
		0 == rand(2) ? :buy : :sell
	end
	alias_method :trade, :coin_flip

	def self.thirds(vector)
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

