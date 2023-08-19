# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/string'
require 'daru'
require 'date'
require 'descriptive_statistics'
require 'mixlib/cli'
require 'mixlib/config'
require 'nenv'
require 'pathname'
require "version_gem"

unless defined?(HOME)
	HOME = Pathname.new(Nenv.home)
end


module SQA
	Signal = {
		hold: 0,
		buy: 	1,
		sell: 2
	}.freeze

	Trend = {
		up: 	0,
		down: 1
	}.freeze

	Swing = {
		valley: 0,
		peak: 	1,
	}.freeze

	module Config
    extend Mixlib::Config
    config_strict_mode true

    default :data_dir,  					HOME + "sqa_data"
    default :plotting_library, 		:gruff  # TODO: use svg-graph
    default :lazy_update,  				false
    default :portfolio_filename,	"portfolio.csv"
    default :trades_filename,    	"trades.csv"

  	default :log_level, 	:info
  	default :config_file, "~/.sqa.rb"

	end

	def self.init
		SQA::CLI.new.run if defined? SQA::CLI

		Config.config_file 		= Pathname.new homify(Config.config_file)

		Config.from_file(Config.config_file)

		Config.data_dir 			= Pathname.new homify(Config.data_dir)

		Daru.lazy_update 			= Config.lazy_update
		Daru.plotting_library = Config.plotting_library

		nil
	end

	def self.homify(filepath)
		filepath.gsub(/^~/, Nenv.home)
	end
end

# require_relative "patches/daru" # TODO: extract Daru::DataFrame in new gem sqa-data_frame

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
