# lib/sqa.rb
# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/string'
require 'daru'
require 'date'
require 'descriptive_statistics'
require 'nenv'
require 'pathname'

require_relative "sqa/version"


unless defined?(HOME)
	HOME = Pathname.new(Nenv.home)
end


module SQA
	class << self
		@@config = nil

		def init(argv=ARGV)
			if argv.is_a? String
				argv = argv.split()
			end


			# Ran at SQA::Config elaboration time
			# @@config = Config.new

			if defined? CLI
				CLI.run(argv)
			else
				# There are no real command line parameters
				# because the sqa gem is be required within
				# the context of a larger program.
			end

			Daru.lazy_update 			= config.lazy_update
			Daru.plotting_library = config.plotting_library

			if config.debug? || config.verbose?
				debug_me{[
					:config
				]}
			end

			nil
		end

		def homify(filepath)
			filepath.gsub(/^~/, Nenv.home)
		end

		def config
			@@config
		end

		def config=(an_object)
			@@config = an_object
		end

		def debug?
			@@config.debug?
		end

		def verbose?
			@@config.verbose?
		end
	end
end

# require_relative "patches/daru" # TODO: extract Daru::DataFrame in new gem sqa-data_frame

require_relative "sqa/config"
require_relative "sqa/constants"
require_relative "sqa/data_frame"
require_relative "sqa/errors"
require_relative "sqa/indicator"
require_relative "sqa/portfolio"
require_relative "sqa/strategy"
require_relative "sqa/stock"
require_relative "sqa/trade"
