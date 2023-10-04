# sqa/lib/sqa/data_frame_2.rb
#
# Thinking about an agnostic-ish way to handle
# 3rd part data frame libraries and still keep some
# consistency between them.  That typically means
# a wrapper class with information hiding and
# adapter modules for each valid 3rd party library.

class SQA::DataFrame2
  REQUIRED_METHODS_FROM_ADAPTER = [
    :append,  # append)new_df)      -- appends new_df to @df
    :load,    # load(path_to_file)  -- loads file into @df
  ]

  # Create an empty data frame
  def initialize(df = Rover::DataFrame.new)
    @df 	= df
    @type = df.class.name.split(':').first.downcase.to_sym

    self.class.include_adapter_for(@type)
    validate_required_methods_present
  end


  def validate_required_methods_present
    methods_missing = []
    REQUIRED_METHODS_FROM_ADAPTER.each do |method_name|
      methods_missing << method_name unless respond_to?(method_name)
    end

    raise "Missing Methods: #{methods_missing.join(', ')}" unless methods_missing.empty?
  end


  def method_missing(method, *args, &block)
    @df.send(method, *args, &block)
  end


  def self.method_missing(method, *args, &block)
    @df.class.send(method, *args, &block)
  end

  #######################################################

  # Adapter this class to a 3rd party data frame library using
  # custom adapter modules that have the expected methods.
  # What are those expected methods?  Well, #load and #append
  # are the only ones that I've considered so far.

  def self.include_adapter_for(data_frame_type)
    case data_frame_type
    when :rover
      include SQA::DataFrame2::RoverAdapter
    when :redamber
      include SQA::DataFrame2::RedamberAdapter
    when :daru
      include SQA::DataFrame2::DaruAdapter
    when :polars
      include SQA::DataFrame2::PolarsAdapter
    else
      raise "Invalid data frame type: #{data_frame_type}"
    end
  end
end


__END__

require 'minitest/autorun'

module Rover
  def self.new; end
end

module Polars
  def self.new; end
end

module RedAmber
  def self.new; end
end

module Daru
  def self.new; end
end

class TestDataFrame < Minitest::Test
  def test_include_adapter_for_rover
    df = SQA::DataFrame2.new(Rover.new)
    assert_includes df.class.included_modules, SQA::DataFrame2::RoverAdapter
  end

  def test_include_adapter_for_polars
    df = SQA::DataFrame2.new(Polars.new)
    assert_includes df.class.included_modules, SQA::DataFrame2::PolarsAdapter
  end

  def test_include_adapter_for_redamber
    df = SQA::DataFrame2.new(RedAmber.new)
    assert_includes df.class.included_modules, SQA::DataFrame2::RedamberAdapter
  end

  def test_include_adapter_for_polars
    df = SQA::DataFrame2.new(Daru.new)
    assert_includes df.class.included_modules, SQA::DataFrame2::DaruAdapter
  end

  def test_include_adapter_for_invalid_type
    df = SQA::DataFrame2.new(Object.new)
    assert_raises(RuntimeError) do
      df.include_adapter_for(:invalid)
    end
  end

  # def test_method_missing
  #   df = SQA::DataFrame.new(Object.new)
  #   df.load("path/to/file")
  #   assert_equal "path/to/file", df.instance_variable_get(:@df)
  # end

  # def test_method_missing_class
  #   SQA::DataFrame.load("path/to/file")
  #   assert_equal "path/to/file", SQA::DataFrame.instance_variable_get(:@df)
  # end
end


