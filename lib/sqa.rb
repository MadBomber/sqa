# lib/sqa.rb
# frozen_string_literal: true

# TODO: Create a new gem for the dumbstockapi website

#############################################
## Standard Libraries

require 'date'
require 'pathname'

unless defined?(HOME)
	HOME = Pathname.new(ENV['HOME'])
end

#############################################
## Additional Libraries

require 'active_support/core_ext/string'
require 'alphavantage' 	# TODO: add rate limiter to it; ** PR submitted! **
require 'api_key_manager'
require 'amazing_print'
require 'descriptive_statistics'
require 'faraday'
require 'hashie'
require 'nenv'
require 'prophet'
require 'rover-df'
require 'sem_version'
require 'sem_version/core_ext'
require 'tty-option'
require 'tty-table'


#############################################
## SQA soecufuc code

require_relative "sqa/version"
require_relative "sqa/errors"

require_relative 'sqa/init.rb'


# TODO: Some of these components make direct calls to the
# 			Alpha Vantage API.  Convert them to use the
# 			alphavantage gem.

require_relative "sqa/config"
require_relative "sqa/constants" 	# SMELL: more app than gem
require_relative "sqa/data_frame"
require_relative "sqa/indicator"
require_relative "sqa/portfolio"
require_relative "sqa/strategy"
require_relative "sqa/stock"
require_relative "sqa/ticker"
require_relative "sqa/trade" # SMELL: Not really a core gem; more of an application thing


