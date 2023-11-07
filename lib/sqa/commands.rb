# sqa/lib/sqa/commands.rb

module SQA::Commands
	# Establish the command registry
  extend Dry::CLI::Registry
end

Commands = SQA::Commands


load_these_first = [
  # TODO: will need the overloaded help here as well
  "#{__dir__}/commands/base.rb",
].each { |file| require_relative file }

Dir.glob("#{__dir__}/commands/*.rb")
  .reject{|file| load_these_first.include? file}
  .each do |file|
  # print "Loading #{file} ... "
  require_relative file
  # puts "done."
end
