# lib/sqa/strategry/sma.rb

require_relative 'trade_against'

class SQA::Strategy::SMA
	extend SQA::Strategy::TradeAgainst

	def self.trade(vector)
		sma_trend = vector.rsi[:trend]

		if :up == sma_trend
			:buy
		elsif :down == sma_trend
			:sell
		else
			:hold
		end
	end
end
