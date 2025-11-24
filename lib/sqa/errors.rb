# lib/sqa/errors.rb

module SQA
  # Raised when unable to fetch data from a data source (API, file, etc.)
  class DataFetchError < StandardError
    attr_reader :original_error

    def initialize(message, original: nil)
      @original_error = original
      super(message)
    end
  end

  # Raised when SQA configuration is invalid or missing
  class ConfigurationError < StandardError; end
end

# raised when an API error occurs
class ApiError < RuntimeError
  def self.raise(why)
    debug_me {"API Error: #{why}"}
    super
  end
end

# raised when a method is not yet implemented
class NotImplemented < RuntimeError
  def self.raise
    debug_me {"Not Yet Implemented"}
    super
  end
end

# raised when an API contract is broken
# Keep both namespaced and global for backward compatibility
module SQA
  class BadParameterError < ArgumentError; end
end
BadParameterError = SQA::BadParameterError
