# lib/sqa/trade.rb


class SQA::Trade
	attr_accessor :df

	def initialize(
				filename = SQA::Config.trades_filename
			)
		@df = SQA::DataFrame.load(filename)
	end

	def place(signal, ticker, shares, price=nil)
		# TODO: insert row into @df

		uuid = rand(100000) # FIXME: place holder
	end

	def confirm(uuid, shares, price)
		# TODO: update the row in the data frame
	end

	def save
		# TODO: save the data frame
	end
end
