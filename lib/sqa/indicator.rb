# lib/sqa/indicators.rb

class SQA::Indicator
end

# setup a shortcut for the namespace
SQAI = SQA::Indicator

Dir["indicator/*.rb"].each do |file|
  require_relative file
end
