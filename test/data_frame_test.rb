# sqa/test/data_frame_test.rb

require_relative  'test_helper'

class DataFrameTest < Minitest::Test

	def test_setup
		assert defined?(SQA)
		assert defined?(SQA::DataFrame)
		assert defined?(SQA::DataFrame::Data)
	end

  def test_empty_data_frame
  	df = SQA::DataFrame.new

  	assert df.empty?
  end

end

__END__

