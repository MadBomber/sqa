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

  def auto_load(except: [:common], only: [])
    dir_path  = Pathname.new(__dir__) + "strategy"
    except    = Array(except).map{|f| f.to_s.downcase}
    only      = Array(only).map{|f| f.to_s.downcase}

    debug_me{[
      :dir_path,
      "dir_path.exist?",
      :except,
      :only
    ]}

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


