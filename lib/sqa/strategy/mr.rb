# lib/sqa/strategry/mr.rb

require_relative 'common'

class SQA::Strategy::MR
	extend SQA::Strategy::Common

	def self.trade(vector)
		if vector.mr
			:sell
		else
			:hold
		end
	end
end
