# lib/sqa/indicators.rb

module SQA::Indicators
end

Dir["indicators/*.rb"].each do |file|
  require_relative file
end
