# lib/sqa/strategry/ema.rb

require_relative 'trade_against'

class SQA::Strategy::EMA
	extend SQA::Strategy::TradeAgainst

	def self.trade(vector)
		ema_trend = vector.ema[:trend]

		if :up == ema_trend
			:buy
		elsif :down == ema_trend
			:sell
		else
			:hold
		end
	end
end
