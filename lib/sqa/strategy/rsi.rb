# lib/sqa/strategry/rsi.rb

require_relative 'common'

class SQA::Strategy::RSI
	extend SQA::Strategy::Common

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
