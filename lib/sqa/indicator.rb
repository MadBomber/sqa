# lib/sqa/indicator.rb

class SQA::Indicator
end

# setup a shortcut for the namespace
SQAI = SQA::Indicator

Dir[__dir__ + "/indicator/*.rb"].each do |file|
  load file
end
