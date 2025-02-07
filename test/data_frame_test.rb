require_relative 'test_helper'

class DataFrameTest < Minitest::Test
  def setup
    @hash_data = {
      'Column1' => [1, 2, 3],
      'Column2' => [4, 5, 6],
      'Column3' => [7, 8, 9]
    }

    @df = SQA::DataFrame.new(@hash_data)
  end

  def test_initialization_with_hash
    assert_equal 3, @df.ncols
    assert_equal 3, @df.nrows
  end

  def test_column_names
    expected_columns = ["Column1", "Column2", "Column3"]
    assert_equal expected_columns, @df.columns
  end

  def test_to_h
    expected_hash = {
      Column1: [1, 2, 3],
      Column2: [4, 5, 6],
      Column3: [7, 8, 9]
    }
    assert_equal expected_hash, @df.to_h
  end

  def test_rename_columns
    @df.rename_columns!({'column1': 'First', 'column2': 'Second', 'column3': 'Third'})
    expected_columns = ["First", "Second", "Third"]
    assert_equal expected_columns, @df.columns
  end

  def test_append_dataframe
    new_data = {
      'Column1' => [10],
      'Column2' => [11],
      'Column3' => [12]
    }
    # Resetting other_df to mirror single appended operation predictably
    other_df = SQA::DataFrame.new(new_data)

    @df.append!(other_df)
    assert_equal 4, @df.nrows
  end

  def test_apply_transformers
    transformers = {
      'Column1': ->(v) { v * 10 },
      'Column2': ->(v) { v + 100 },
      'Column3': ->(v) { v.to_s }
    }
    @df.apply_transformers!(transformers)
    transformed_hash = {
      Column1: [10, 20, 30],
      Column2: [104, 105, 106],
      Column3: ['7', '8', '9']
    }
    assert_equal transformed_hash, @df.to_h
  end

  def test_to_csv
    require 'tempfile'
    file = Tempfile.new('test.csv')
    @df.to_csv(file.path)
    csv_contents = CSV.read(file.path)
    assert_equal ['Column1', 'Column2', 'Column3'], csv_contents.first
  end

  def test_size_methods
    assert_equal 3, @df.nrows
    assert_equal 3, @df.ncols
  end

  def test_is_date
    assert SQA::DataFrame.is_date?('2023-04-01')
    refute SQA::DataFrame.is_date?('NotADate')
  end
end
