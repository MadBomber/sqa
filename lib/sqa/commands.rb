# sqa/lib/sqa/commands.rb

module SQA::Commands
	# Establish the command registry
  extend Dry::CLI::Registry
end


Dir[__dir__ + "/commands/*.rb"].each do |file|
  load file
end
