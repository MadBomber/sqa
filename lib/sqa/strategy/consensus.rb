# lib/sqa/strategry/consensus.rb

require_relative 'common'

class SQA::Strategy::Consensus
	extend SQA::Strategy::Common

	def self.trade(vector)
		new(vector).my_fancy_trader
	end

	def initialize(vector)
		@vector 	= vector
		@results 	= []
	end

	def my_fancy_trader
		strat_one
		strat_two
		strat_three
		strat_four
		strat_five
		consensus
	end

	def consensus
		count = @results.group_by(&:itself).transform_values(&:count)

		if count[:buy] > count[:sell]
			:buy
		elsif count[:sell] > count[:buy]
			:sell
		else
			:hold
		end
	end

	def strat_one 	= @results << (0==rand(2) ? :buy : :sell)
	def strat_two 	= @results << (0==rand(2) ? :buy : :sell)
	def strat_three = @results << (0==rand(2) ? :buy : :sell)
	def strat_four 	= @results << (0==rand(2) ? :buy : :sell)
	def strat_five 	= @results << :hold
end
