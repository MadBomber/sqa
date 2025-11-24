# sqa/lib/sqa/init.rb

module SQA
	class << self
		# Class instance variables (thread-safer than @@class_variables)
		attr_writer :config

		# Initializes the SQA modules
		# returns the configuration
		#
		def init(argv=ARGV)
			if argv.is_a? String
				argv = argv.split()
			end


			# Ran at SQA::Config elaboration time
			# @config = Config.new

			if defined? CLI
				CLI.run!    # TODO: how to parse a fake argv?  (argv)
			else
				# There are no real command line parameters
				# because the sqa gem is being required within
				# the context of a larger program.
			end

			config.data_dir = homify(config.data_dir)

			config
		end

		def av_api_key
			@av_api_key ||= ENV['AV_API_KEY'] || ENV['ALPHAVANTAGE_API_KEY']
			@av_api_key || raise(SQA::ConfigurationError, 'Alpha Vantage API key not set. Set AV_API_KEY or ALPHAVANTAGE_API_KEY environment variable.')
		end

		def av_api_key=(key)
			@av_api_key = key
		end

		# Legacy accessor for backward compatibility
		def av
			self
		end

		# For compatibility with old SQA.av.key usage
		def key
			av_api_key
		end

		def debug?() 						= @config&.debug?
		def verbose?() 					= @config&.verbose?

		def homify(filepath) 		= filepath.gsub(/^~/, Nenv.home)
		def data_dir() 					= Pathname.new(config.data_dir)
		def config()            = @config
	end
end
