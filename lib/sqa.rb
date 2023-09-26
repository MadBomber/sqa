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
require 'alphavantage' 	# TODO: add rate limiter to it
require 'amazing_print'
require 'daru' 					# TODO: Replace this gem with something better
require 'descriptive_statistics'
require 'faraday'
require 'hashie'
require 'nenv'
require 'sem_version'
require 'sem_version/core_ext'
require 'tty-option'
require 'tty-table'

require 'api_key_manager' # FIXME: currently from lib/ruby

#############################################
## SQA soecufuc code

require_relative "sqa/version"
require_relative "sqa/errors"

require_relative 'sqa/init.rb'

# require_relative "patches/daru" # TODO: extract Daru::DataFrame in new gem sqa-data_frame

# TODO: Some of these components make direct calls to the
# 			Alpha Vantage API.  Convert them to use the
# 			alphavantage gem.

require_relative "sqa/config"
require_relative "sqa/constants" 	# SMELL: more app than gem
require_relative "sqa/data_frame" # TODO: drop the daru gem
require_relative "sqa/indicator"
require_relative "sqa/portfolio"
require_relative "sqa/strategy"
require_relative "sqa/stock"
require_relative "sqa/ticker"
require_relative "sqa/trade" # SMELL: Not really a core gem; more of an application thing


