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
	$DEBUG_ME = true
else
	begin
		require 'debug_me'
		include DebugMe
		$DEBUG_ME = true
	rescue LoadError
		# debug_me is optional - define a no-op if not available
		def debug_me(tag = nil, &block)
			# No-op when debug_me gem is not available
		end
		$DEBUG_ME = false
	end
end

#############################################
## Additional Libraries

begin
  require 'amazing_print'
rescue LoadError
  # amazing_print is optional (development dependency)
end
require 'faraday'
require 'hashie'
require 'lite/statistics'
require 'lite/statistics/monkey_patches' # patch to Enumerable
require 'nenv'
require 'tty-table'


#############################################
## Apply core class monkey patches

# Using these monkey patches to remove need for
# ActiveSupport
require_relative "patches/string.rb"


#############################################
## API wrappers for External Websites

require_relative "api/alpha_vantage_api"


#############################################
## SQA specific code

require_relative "sqa/version"
require_relative "sqa/errors"

require_relative 'sqa/init.rb'

require_relative "sqa/config"
require_relative "sqa/data_frame"
require_relative "sqa/indicator"
require_relative "sqa/fpop"
require_relative "sqa/market_regime"
require_relative "sqa/seasonal_analyzer"
require_relative "sqa/sector_analyzer"
require_relative "sqa/portfolio"
require_relative "sqa/backtest"
require_relative "sqa/strategy"
require_relative "sqa/stock"
require_relative "sqa/ticker"
require_relative "sqa/stream"
require_relative "sqa/gp"
require_relative "sqa/strategy_generator"
require_relative "sqa/risk_manager"
require_relative "sqa/portfolio_optimizer"
require_relative "sqa/ensemble"
require_relative "sqa/multi_timeframe"
require_relative "sqa/pattern_matcher"


