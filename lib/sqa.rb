# lib/sqa.rb
# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/string'
require 'daru'
require 'date'
require 'descriptive_statistics'
require 'nenv'
require 'pathname'

unless defined?(HOME)
	HOME = Pathname.new(Nenv.home)
end


module SQA
	class << self
		@@config = nil

		def init
			Config.run
			CLI.run 		if defined? CLI


			Config.config[:data_dir] = Pathname.new homify(Config.congif[:data_dir])

			Daru.lazy_update 			= Config.config[:lazy]
			Daru.plotting_library = Config.config[:plot_lib]

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
require_relative "sqa/version"


SQA::Version.class_eval do
  extend VersionGem::Basic
end
