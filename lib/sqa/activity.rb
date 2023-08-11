# lib/sqa/activity.rb

# Historical daily stock activity
# primary id is [ticker, date]

class SQA::Activity < ActiveRecord::Base
	# belongs_to :stock using ticker as the foreign key
	# need a unique constraint on [ticker, date]
	# should date be saved as a Date object or string?
end
