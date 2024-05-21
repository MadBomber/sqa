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


  def test_data
    debug_me{[
      "@hofa",
      "'======'",
      "@df",
      "'======'",
      "@df.to_hash"
    ]}
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
      'Column1' => 'one',
      'Column2' => 'two',
      'Column3' => 'three'
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
  	columns = %i[ column1 column2 column3 ]
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

    assert_equal ['column1', 'column2', 'column3'], csv_contents.first
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
			column1: :one,
			column2: :two,
			column3: :three
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

  def test_new
    hofa  = {
      'C1' => [1, 2, 3],
      'C2' => [4, 5, 6]
    }

    expected_keys = %i[ c1 c2 ]

    df = SQA::DataFrame.new(hofa)

    assert_equal expected_keys, df.keys
  end


  def test_class_concat
    hofa  = @df.to_hash

    # debug_me{[
    #   "hofa.keys"
    # ]}

    df1   = SQA::DataFrame.new(hofa)
    df2   = SQA::DataFrame.new(hofa)

    expected_columns = %i[ column1 column2 column3 ]

    result_df = SQA::DataFrame.concat(df1, df2)

    assert_equal expected_columns, result_df
    assert_equal [1, 2, 3, 1, 2, 3], result_df[:column1]
    assert_equal [4, 5, 6, 4, 5, 6], result_df[:column2]
    assert_equal [7, 8, 9, 7, 8, 9], result_df[:column3]
  end


  def test_class_load
    Tempfile.create(['test', '.csv']) do |f|
      f.write("Column1,Column2\n1,2\n3,4")
      f.rewind
      df = SQA::DataFrame.load(source: Pathname.new(f.path))

      assert_instance_of SQA::DataFrame, df
      assert_equal [['1', '2'], ['3', '4']], df.rows
    end
  end


  def test_class_from_aofh
    aofh = [{'Column1' => 1, 'Column2' => 2}, {'Column1' => 3, 'Column2' => 4}]
    df = SQA::DataFrame.from_aofh(aofh)

    assert_instance_of SQA::DataFrame, df
    assert_equal 2, df.nrows
    assert_equal [1, 3], df.column1.to_a
    assert_equal [2, 4], df.column2.to_a
  end


  def test_class_from_csv_file
    Tempfile.create(['test', '.csv']) do |f|
      f.write("Column1,Column2\n5,6\n7,8")
      f.rewind
      df = SQA::DataFrame.from_csv_file(f.path)

      assert_instance_of SQA::DataFrame, df
      assert_equal [['5', '6'], ['7', '8']], df.rows
    end
  end


  def test_class_from_json_file
    Tempfile.create(['test', '.json']) do |f|
      f.write('[{"Column1": 9, "Column2": 10}, {"Column1": 11, "Column2": 12}]')
      f.rewind
      df = SQA::DataFrame.from_json_file(f)

      assert_instance_of SQA::DataFrame, df
      assert_equal [[9, 10], [11, 12]], df.rows.map { |row| row.map(&:to_i) }
    end
  end


  def test_class_aofh_to_hofa
    aofh    = [{'Column1' => 'A', 'Column2' => 'B'}, {'Column1' => 'C', 'Column2' => 'D'}]
    result  = SQA::DataFrame.aofh_to_hofa(aofh)

    expected  = {
      column1: ['A', 'C'], 
      column2: ['B', 'D']
    }
    
    assert_equal expected, result
  end


  def test_class_normalize_keys
    # skip "bad business logic or misunderstood requirement"
    hofa  = {
      'Some Column'     => [1, 2], 
      ' AnotherColumn'  => [3, 4]}
    normalized_hofa = SQA::DataFrame.normalize_keys(hofa)

    expected_keys = [:some_column, :another_column]
    
    assert_equal expected_keys, normalized_hofa.keys
  end


  def test_class_rename
    mapping = {
      "Column1" => :NewName1, 
      "Column2" => :NewName2
    }

    hofa    = {
      'Column1' => [1, 2], 
      'Column2' => [3, 4]
    }

    renamed_hofa = SQA::DataFrame.rename(mapping, hofa)

    assert_equal [:NewName1, :NewName2], renamed_hofa.keys
  end


  def test_class_generate_mapping
    keys = ['Test Column', 'AnotherColumn']
    mapping = SQA::DataFrame.generate_mapping(keys)

    expected  = { 
      'Test Column'   => :test_column, 
      'AnotherColumn' => :another_column 
    }

    assert_equal(expected, mapping)
  end


  def test_class_underscore_key
    # skip "bad test ?"
    assert_equal :a_test_key, SQA::DataFrame.underscore_key("A Test Key")
    assert_equal :another_test, SQA::DataFrame.underscore_key("AnotherTest")
  end


  def test_class_sanitize_key
    # skip "bug lets the ! through"
    assert_equal :a_clean_key,        SQA::DataFrame.sanitize_key("A Clean Key!")
    assert_equal :numbers_123_are_ok, SQA::DataFrame.sanitize_key("Numbers 123 Are OK!")
  end


  def test_class_is_date?
    assert SQA::DataFrame.is_date?("2023-04-01")
    refute SQA::DataFrame.is_date?("NotADate")
  end
end
