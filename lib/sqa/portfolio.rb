# lib/sqa/portfolio.rb

class SQA::Portfolio
	attr_accessor :df

	def initialize(filename="portfolio.csv")
		@df = SQA::DataFrame.load(filename)
	end
end
