# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/string'
require 'daru'
require 'date'

require 'debug_me'
include DebugMe

require 'descriptive_statistics'
require 'mixlib/config'
require 'nenv'
require 'pathname'
require "version_gem"

unless defined?(HOME)
	HOME = Pathname.new(Nenv.home)
end


module SQA
	module Config
    extend Mixlib::Config
    config_strict_mode true

    default :data_dir,  				HOME + "sqa_data"
    default :plotting_library, 	:gruff
    default :lazy_update,  			false
	end

	def self.init
		Daru.lazy_update 			= Config.lazy_update
		Daru.plotting_library = Config.plotting_library

		nil
	end
end

require_relative "sqa/data_frame"
require_relative "sqa/errors"
require_relative "sqa/indicator"
require_relative "sqa/strategy"
require_relative "sqa/stock"
require_relative "sqa/version"


SQA::Version.class_eval do
  extend VersionGem::Basic
end
