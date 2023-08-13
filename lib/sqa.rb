# frozen_string_literal: true

module SQA
end

require 'csv'
require 'date'

require 'debug_me'
include DebugMe

require 'descriptive_statistics'

require 'json'
require 'pathname'

require_relative "sqa/version"
require_relative "sqa/errors"
require_relative "sqa/indicator"
