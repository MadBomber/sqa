# lib/sqa/strategy.rb

class SQA::Strategy
  attr_accessor :strategies

  def initialize
    @strategies = []
  end

  def add(a_strategy)
    raise SQA::BadParameterError unless [Class, Method].include? a_strategy.class

    a_proc  = if Class == a_strategy.class
                a_strategy.method(:trade)
              else
                a_strategy
              end

    @strategies << a_proc
  end

  def execute(v)
    result = []
    # TODO: Can do this in parallel ...
    @strategies.each { |signal| result << signal.call(v) }
    result
  end

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

  def available
    ObjectSpace.each_object(Class).select { |klass|
      klass.to_s.start_with?("SQA::Strategy::")
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

