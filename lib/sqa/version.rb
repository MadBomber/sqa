# frozen_string_literal: true

require 'sem_version'
require 'sem_version/core_ext'

module SQA
  VERSION = "0.0.9"

  class << self
    def version
      @@version ||= VERSION.to_version
    end
  end
end
