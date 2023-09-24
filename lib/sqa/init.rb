# sqa/lib/sqa/init.rb

module SQA
	class << self
		@@config = nil

		# Initializes the SQA modules
		# returns the configuration
		#
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
				# because the sqa gem is being required within
				# the context of a larger program.
			end

			config.data_dir = homify(config.data_dir)

			Daru.lazy_update 			= config.lazy_update
			Daru.plotting_library = config.plotting_library

			config
		end

		def debug?() 						= @@config.debug?
		def verbose?() 					= @@config.verbose?

		def homify(filepath) 		= filepath.gsub(/^~/, Nenv.home)
		def data_dir() 					= Pathname.new(config.data_dir)
		def config()            = @@config

		def config=(an_object)
			@@config = an_object
		end
	end
end
