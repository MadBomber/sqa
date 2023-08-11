# lib/sqa/portfolio.rb

# A collection of stocks
# primary id is ticker  its unique

class SQA::Portfolio < ActiveRecord::Base
	has_many :stocks # use ticker as the foreign key
end
