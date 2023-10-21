# sqa/test/data_frame_test.rb

require_relative  'test_helper'

class DataFrameTest < Minitest::Test
  def setup
    # Normal: Hash of Arrays without key mapping and transformers
    @hofa = {
      'Column1' => [1, 2, 3],
      'Column2' => [4, 5, 6],
      'Column3' => [7, 8, 9]
    }

    @df = SQA::DataFrame.new(@hofa)
  end


	def test_classes_defined
		assert defined?(SQA)
		assert defined?(SQA::DataFrame)
		assert defined?(SQA::DataFrame::Data)
	end


  def test_empty_data_frame
    df = SQA::DataFrame.new
    assert df.empty?
  end


  def test_creation_normal_hofa_no_mapping_no_transformers
    assert_instance_of SQA::DataFrame, @df
    assert_equal 3, @df.ncols
    assert_equal 3, @df.nrows
  end


  def test_creation_normal_hofa_with_mapping_no_transformers
    mapping = {
      'Column1' => :one,
      'Column2' => :two,
      'Column3' => :three
    }

    df = SQA::DataFrame.new(@hofa, mapping: mapping)

    assert_instance_of SQA::DataFrame, df
    assert_equal 3, df.ncols
    assert_equal 3, df.nrows

    assert_equal [:one, :two, :three], df.keys
  end



  def test_creation_normal_hofa_no_mapping_with_transformers
    transformers = {
      Column1: -> (v) {v + 100}
    }

    df = SQA::DataFrame.new(@hofa, transformers: transformers)

    assert_instance_of SQA::DataFrame, df
    assert_equal 3, df.ncols
    assert_equal 3, df.nrows

    assert_equal [101, 102, 103], df.Column1.to_a # to_a converts from Hashie::Array to Array
  end


  def test_creation_normal_hofa_with_mapping_with_transformers
    mapping = {
      'Column1' => :one,
      'Column2' => :two,
      'Column3' => :three
    }

    transformers = {
      one: -> (v) {v + 100}
    }

    df = SQA::DataFrame.new(
            @hofa,
            mapping:      mapping,
            transformers: transformers
          )

    assert_instance_of SQA::DataFrame, df
    assert_equal 3, df.ncols
    assert_equal 3, df.nrows

    assert_equal [:one, :two, :three], df.keys
    assert_equal [101, 102, 103], df.one.to_a # to_a converts from Hashie::Array to Array
  end


  def test_ways_to_access_data_frame_content
  	given = {
  		"one" => "1",
  		"two" => "2"
  	}

  	df = SQA::DataFrame.new(given)

  	assert_equal "1", df["one"]
  	assert_equal "1", df[:one]
  	assert_equal "1", df.one

  	assert_equal "2", df["two"]
  	assert_equal "2", df[:two]
  	assert_equal "2", df.two
  end


  def test_column_names
  	columns = %i[ Column1 Column2 Column3 ]
    assert_equal columns, @df.vectors
    assert_equal columns, @df.keys
  end


  def test_row_access
    assert_equal [2, 5, 8], @df.row(1)
  end


  def test_to_csv
    file = Tempfile.new('test.csv')
    @df.to_csv(file.path)

    csv_contents = CSV.read(file.path)

    assert_equal ['Column1', 'Column2', 'Column3'], csv_contents.first
    assert_equal ['1', '4', '7'], csv_contents[1]
    assert_equal ['3', '6', '9'], csv_contents.last
  end


  def test_append
    new_df = SQA::DataFrame.new({
      'Column1' => [4],
      'Column2' => [10],
      'Column3' => [14]
    })

    @df.append!(new_df)

    assert_equal 4, @df.nrows
    assert_equal [4, 10, 14], @df.row(3)
  end


  def test_to_h
    expected = {
      Column1: [1, 2, 3],
      Column2: [4, 5, 6],
      Column3: [7, 8, 9]
    }

    assert_equal expected, @df.to_h
  end


  def test_values
		expected = [
			[1,2,3],
			[4,5,6],
			[7,8,9]
		]

		# NOTE: to_a converts from Hashie::Array to Array
		assert_equal expected, @df.values.map(&:to_a)
  end


  def test_rows
		expected = [
			[1, 4, 7],
			[2, 5, 8],
			[3, 6, 9]
		]

		assert_equal expected, @df.rows
		assert_equal expected, @df.values.transpose
	end


	def test_rename
		mapping = {
			Column1: :one,
			Column2: :two,
			Column3: :three
		}

		df = @df.rename(mapping)

		assert_equal %i[ one two three ], df.keys
	end


	def test_coerce_vectors
		transformers = {
    	Column1: -> (v) {v + 100},
    	Column2: -> (v) {v.to_f.round(1)},
    	Column3: -> (v) {v.to_s}
  	}

  	@df.coerce_vectors!(transformers)

  	assert_equal [101, 102, 103], @df.Column1
  	assert_equal [4.0, 5.0, 6.0], @df.Column2
  	assert_equal ["7", "8", "9"], @df.Column3
	end


	#########################
	## Class Methods Tests ##
	#########################


  def test_class_concat
  	skip
  end


  def test_class_load
  	skip
  end


  def test_class_from_aofh
  	skip
  end


  def test_class_from_csv_file
  	skip
  end


  def test_class_from_json_file
  	skip
  end


  def test_class_aofh_to_hofa
  	skip
  end


  def test_class_normalize_keys
  	skip
  end


  def test_class_rename
  	skip
  end


  def test_class_generate_mapping
  	skip
  end


  def test_class_underscore_key
  	skip
  end


  def test_class_sanitize_key
  	skip
  end


  def test_class_is_date?
  	skip
  end

end
