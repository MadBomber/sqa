# lib/sqa/strategy.rb

# Framework for managing and executing trading strategies.
# Strategies are pluggable modules that generate buy/sell/hold signals.
#
# @example Basic usage
#   strategy = SQA::Strategy.new
#   strategy.add(SQA::Strategy::RSI)
#   strategy.add(SQA::Strategy::MACD)
#   signals = strategy.execute(vector)  # => [:buy, :hold]
#
# @example Auto-loading strategies
#   strategy = SQA::Strategy.new
#   strategy.auto_load(except: [:random])
#
class SQA::Strategy
  # @!attribute [rw] strategies
  #   @return [Array<Method>] Collection of strategy trade methods
  attr_accessor :strategies

  # Creates a new Strategy instance with an empty strategies collection.
  def initialize
    @strategies = []
  end

  # Adds a trading strategy to the collection.
  # Strategies must be either a Class with a .trade method or a Method object.
  #
  # @param a_strategy [Class, Method] Strategy to add
  # @return [Array<Method>] Updated strategies collection
  # @raise [BadParameterError] If strategy is not a Class or Method
  #
  # @example Adding a class-based strategy
  #   strategy.add(SQA::Strategy::RSI)
  #
  # @example Adding a method directly
  #   strategy.add(MyModule.method(:custom_trade))
  #
  def add(a_strategy)
    raise BadParameterError unless a_strategy.is_a?(Class) || a_strategy.is_a?(Method)

    a_proc  = if a_strategy.is_a?(Class)
                a_strategy.method(:trade)
              else
                a_strategy
              end

    @strategies << a_proc
  end

  # Executes all registered strategies with the given data vector.
  #
  # @param v [OpenStruct] Data vector containing indicator values and prices
  # @return [Array<Symbol>] Array of signals (:buy, :sell, or :hold) from each strategy
  #
  # @example
  #   vector = OpenStruct.new(rsi: 25, prices: prices_array)
  #   signals = strategy.execute(vector)  # => [:buy, :hold, :sell]
  #
  def execute(v)
    result = []
    # NOTE: Could be parallelized with Parallel gem for large strategy sets
    @strategies.each { |signal| result << signal.call(v) }
    result
  end

  # Auto-loads strategy files from the strategy directory.
  #
  # @param except [Array<Symbol>] Strategy names to exclude (default: [:common])
  # @param only [Array<Symbol>] If provided, only load these strategies
  # @return [nil]
  #
  # @example Load all except random
  #   strategy.auto_load(except: [:common, :random])
  #
  # @example Load only specific strategies
  #   strategy.auto_load(only: [:rsi, :macd])
  #
  def auto_load(except: [:common], only: [])
    dir_path  = Pathname.new(__dir__) + "strategy"
    except    = Array(except).map{|f| f.to_s.downcase}
    only      = Array(only).map{|f| f.to_s.downcase}

    dir_path.children.each do |child|
      next unless ".rb" == child.extname.downcase

      basename = child.basename.to_s.split('.').first.downcase

      next if except.include? basename
      next if !only.empty?  && !only.include?(basename)

      print "loading #{basename} ... "
      load child
      puts "done"
    end

    nil
  end

  # Returns all available strategy classes in the SQA::Strategy namespace.
  #
  # @return [Array<Class>] Array of strategy classes
  #
  # @example
  #   SQA::Strategy.new.available
  #   # => [SQA::Strategy::RSI, SQA::Strategy::MACD, ...]
  #
  def available
    ObjectSpace.each_object(Class).select { |klass|
      klass.name&.start_with?("SQA::Strategy::")
    }
  end
end

require_relative 'strategy/common'
require_relative 'strategy/consensus'
require_relative 'strategy/ema'
require_relative 'strategy/mp'
require_relative 'strategy/mr'
require_relative 'strategy/random'
require_relative 'strategy/rsi'
require_relative 'strategy/sma'
require_relative 'strategy/bollinger_bands'
require_relative 'strategy/macd'
require_relative 'strategy/stochastic'
require_relative 'strategy/volume_breakout'
require_relative 'strategy/kbs_strategy'

