# lib/sqa/indicators.rb

module SQA::indicators
end

Dir["indicators/*.rb"].each do |file|
  require_relative file
end
