# lib/sqa/errors.rb

# raised when a method is still in TODO state
class NotImplemented < RuntimeError; end

# raised when an API contract is broken
class BadParameterError < ArgumentError; end
