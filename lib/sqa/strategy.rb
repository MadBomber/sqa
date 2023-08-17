# lib/sqa/strategy.rb

class SQA::Strategy
  attr_accessor :strategies

  def initialize
    @strategies = []
  end

  def add(a_proc=nil, &block)
    @strategies << a_proc unless a_proc.nil?
    @strategies << block  if a_proc.nil? && block_given?
  end

  def execute(v)
    result = []
    # TODO: Can do this in parallel ...
    @strategies.each { |signal| result << signal.call(v) }
    result
  end
end

__END__

Example Usage
=============

ss = SQA::Strategy.new

ss.add do |vector|
  case rand(10)
  when (8..)
    :buy
  when (..3)
    :sell
  else
    :hold
  end
end


ss.add do |vector|
  case rand(10)
  when (8..)
    :sell
  when (..3)
    :buy
  else
    :keep
  end
end

def magic(vector)
  0 == rand(2) ? :spend : :save
end

ss.add method(:magic)

class MyClass
  def self.my_method(vector)
    vector.rsi[:rsi]
  end
end

ss.add MyClass.method(:my_method)
