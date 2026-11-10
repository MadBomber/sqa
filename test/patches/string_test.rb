# frozen_string_literal: true

require_relative '../test_helper'

# Guards String#to_constant (aliased as #constantize), the resolver
# SQA::Stock uses to turn a source name into a DataFrame class. These
# assertions pin the behavior the method must keep so the modern
# const_get path can stand alone.
class StringToConstantTest < Minitest::Test
  def test_resolves_a_namespaced_constant
    assert_equal SQA::Stock, 'SQA::Stock'.constantize
    assert_equal SQA::DataFrame, 'SQA::DataFrame'.constantize
  end

  def test_resolves_a_top_level_constant
    assert_equal String, 'String'.constantize
  end

  def test_tolerates_a_leading_separator
    assert_equal SQA::Stock, '::SQA::Stock'.constantize
  end

  def test_unknown_constant_raises_name_error
    assert_raises(NameError) { 'SQA::NoSuchConstant'.constantize }
    assert_raises(NameError) { 'Totally::Bogus'.constantize }
  end
end
