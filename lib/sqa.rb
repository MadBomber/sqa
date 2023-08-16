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

unless defined?(HOME)
	HOME = Pathname.new(Nenv.home)
end

module SQA
	module Config
    extend Mixlib::Config
    config_strict_mode true

    default :data_dir,  HOME + "sqa_data"
	end
end

require_relative "sqa/data_frame"
require_relative "sqa/errors"
require_relative "sqa/indicator"
require_relative "sqa/stock"
require_relative "sqa/version"
