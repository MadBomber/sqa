# lib/sqa/strategry/rsi.rb

require_relative 'trade_against'

class SQA::Strategy::RSI
	extend SQA::Strategy::TradeAgainst

	def self.trade(vector)
		rsi_trend = vector.rsi[:trend]

		if :over_bought == rsi_trend
			:sell
		elsif :over_sold == rsi_trend
			:buy
		else
			:hold
		end
	end
end
