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

# TODO: do we want to move the debug_me gem out of the
# 			development dependencies into the required?
#
if defined?(DebugMe)
	unless respond_to?(:debug_me)
		include DebugMe
	end
else
	require 'debug_me'
	include DebugMe
end

$DEBUG_ME = true

#############################################
## Additional Libraries

require 'alphavantage'
require 'api_key_manager'
require 'amazing_print'
require 'dry/cli'
require 'faraday'
require 'hashie'
require 'lite/statistics'
require 'lite/statistics/monkey_patches' # patch to Enumerable
require 'nenv'
require 'sem_version'
require 'sem_version/core_ext'
require 'tty-table'


#############################################
## Apply core class monkey patches

# Using these monkey patches to remove need for
# ActiveSupport
require_relative "patches/string.rb"

# Adds the global_header, global_footer, header, and footer
# class methods to enhance the HELP/Usage functionality
require_relative "patches/dry-cli.rb"


#############################################
## SQA specific code

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


