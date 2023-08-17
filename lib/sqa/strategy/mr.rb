# lib/sqa/strategry/mr.rb

require_relative 'trade_against'

class SQA::Strategy::MR
	extend SQA::Strategy::TradeAgainst

	def self.trade(vector)
		if vector.mr
			:sell
		else
			:hold
		end
	end
end
