# lib/sqa/errors.rb
#
# SQA Exception Classes
# All custom exceptions inherit from StandardError or RuntimeError
# to ensure they can be caught by generic rescue blocks.

module SQA
  # Raised when unable to fetch data from a data source (API, file, etc.).
  # Wraps the original exception for debugging purposes.
  #
  # @example Raising with original error
  #   begin
  #     response = api.fetch(ticker)
  #   rescue Faraday::Error => e
  #     raise SQA::DataFetchError.new("Failed to fetch #{ticker}", original: e)
  #   end
  #
  # @example Accessing original error
  #   begin
  #     stock = SQA::Stock.new(ticker: 'INVALID')
  #   rescue SQA::DataFetchError => e
  #     puts e.message
  #     puts e.original_error.class if e.original_error
  #   end
  #
  class DataFetchError < StandardError
    # @return [Exception, nil] The original exception that caused this error
    attr_reader :original_error

    # Creates a new DataFetchError.
    #
    # @param message [String] Error message describing the fetch failure
    # @param original [Exception, nil] The original exception that was caught
    def initialize(message, original: nil)
      @original_error = original
      super(message)
    end
  end

  # Raised when SQA configuration is invalid or missing.
  # Common causes include missing API keys or invalid data directories.
  #
  # @example
  #   raise SQA::ConfigurationError, "API key not set"
  #
  class ConfigurationError < StandardError; end

  # Raised when a method parameter is invalid.
  # Inherits from ArgumentError for semantic clarity.
  #
  # @example
  #   raise SQA::BadParameterError, "Expected a Class or Method"
  #
  class BadParameterError < ArgumentError; end
end

# Global alias for backward compatibility.
# @deprecated Use SQA::BadParameterError instead
BadParameterError = SQA::BadParameterError

# Raised when an external API returns an error response.
# Automatically logs the error using debug_me before raising.
#
# @example
#   ApiError.raise("Rate limit exceeded")
#
class ApiError < RuntimeError
  # Raises an ApiError with debug logging.
  #
  # @param why [String] The error message from the API
  # @raise [ApiError] Always raises after logging
  def self.raise(why)
    debug_me {"API Error: #{why}"}
    super
  end
end

# Raised when a feature is not yet implemented.
# Automatically logs using debug_me before raising.
#
# @example
#   NotImplemented.raise
#
class NotImplemented < RuntimeError
  # Raises a NotImplemented error with debug logging.
  #
  # @raise [NotImplemented] Always raises after logging
  def self.raise
    debug_me {"Not Yet Implemented"}
    super
  end
end
