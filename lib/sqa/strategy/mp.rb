# lib/sqa/strategry/mp.rb

require_relative 'trade_against'

class SQA::Strategy::MP
	extend SQA::Strategy::TradeAgainst

	def self.trade(vector)
		mp = vector.market_profile=:mixed,

		if :resistance == mp
			:sell
		elsif :support == mp
			:buy
		else
			:hold
		end
	end
end
