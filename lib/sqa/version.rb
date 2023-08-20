# frozen_string_literal: true

require 'sem_version'
require 'sem_version/core_ext'

module SQA
  module Version
    VERSION = "0.0.7".to_version
  end

  include Version
end
