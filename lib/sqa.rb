# frozen_string_literal: true

module SQA
end

require 'csv'
require 'daru'
require 'date'

require 'debug_me'
include DebugMe

require 'descriptive_statistics'

require 'json'
require 'pathname'

require_relative "sqa/data_frame"
require_relative "sqa/errors"
require_relative "sqa/indicator"
require_relative "sqa/version"
