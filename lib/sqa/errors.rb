# lib/sqa/errors.rb

# raised when a method is still in TODO state
class NotImplemented < RuntimeError
  def self.raise
    puts "="*64
    puts "== Not Yet Implemented"
    puts "Callback trace:"
    puts caller
    puts "="*64
    super
  end
end

# raised when an API contract is broken
class BadParameterError < ArgumentError; end
