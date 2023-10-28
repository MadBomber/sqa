# frozen_string_literal: true

module SQA
  VERSION = "0.0.23"

  class << self
    def version
      @@version ||= VERSION.to_version
    end
  end
end
