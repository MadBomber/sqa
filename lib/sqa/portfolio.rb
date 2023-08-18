# lib/sqa/portfolio.rb

class SQA::Portfolio
	attr_accessor :df

	def initialize(
				filename = SQA::Config.portfolio_filename
			)
		@df = SQA::DataFrame.load(filename)
	end
end
