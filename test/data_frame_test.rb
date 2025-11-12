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

  def test_concat_and_deduplicate_removes_duplicates
    # Create initial DataFrame with timestamps
    data1 = {
      'timestamp' => ['2024-11-12', '2024-11-11', '2024-11-10'],
      'close_price' => [150.0, 149.0, 148.0],
      'volume' => [1000, 1100, 1200]
    }
    df1 = SQA::DataFrame.new(data1)

    # Create new DataFrame with overlapping timestamp
    data2 = {
      'timestamp' => ['2024-11-13', '2024-11-12'],  # 2024-11-12 is duplicate
      'close_price' => [151.0, 150.0],
      'volume' => [900, 1000]
    }
    df2 = SQA::DataFrame.new(data2)

    # Concatenate with deduplication
    df1.concat_and_deduplicate!(df2)

    # Should have 4 unique timestamps (not 5)
    assert_equal 4, df1.nrows

    # Check timestamps are unique
    timestamps = df1['timestamp'].to_a
    assert_equal 4, timestamps.uniq.size
  end

  def test_concat_and_deduplicate_maintains_descending_order
    # Create initial DataFrame (already descending)
    data1 = {
      'timestamp' => ['2024-11-12', '2024-11-11', '2024-11-10'],
      'close_price' => [150.0, 149.0, 148.0]
    }
    df1 = SQA::DataFrame.new(data1)

    # Create new DataFrame with newer dates
    data2 = {
      'timestamp' => ['2024-11-15', '2024-11-14', '2024-11-13'],
      'close_price' => [153.0, 152.0, 151.0]
    }
    df2 = SQA::DataFrame.new(data2)

    # Concatenate with deduplication
    df1.concat_and_deduplicate!(df2)

    # Check descending order
    timestamps = df1['timestamp'].to_a
    assert_equal ['2024-11-15', '2024-11-14', '2024-11-13', '2024-11-12', '2024-11-11', '2024-11-10'], timestamps
  end

  def test_concat_and_deduplicate_keeps_first_occurrence
    # Create initial DataFrame
    data1 = {
      'timestamp' => ['2024-11-12', '2024-11-11'],
      'close_price' => [150.0, 149.0],
      'volume' => [1000, 1100]
    }
    df1 = SQA::DataFrame.new(data1)

    # Create new DataFrame with duplicate timestamp but different values
    data2 = {
      'timestamp' => ['2024-11-13', '2024-11-12'],  # 2024-11-12 is duplicate
      'close_price' => [151.0, 999.0],  # Different value for duplicate
      'volume' => [900, 9999]
    }
    df2 = SQA::DataFrame.new(data2)

    # Concatenate with deduplication
    df1.concat_and_deduplicate!(df2)

    # Should keep first occurrence (from df1: 150.0, not 999.0)
    timestamps = df1['timestamp'].to_a
    prices = df1['close_price'].to_a

    idx = timestamps.index('2024-11-12')
    assert_equal 150.0, prices[idx]
  end

  def test_concat_and_deduplicate_with_empty_dataframe
    # Create empty DataFrame
    df1 = SQA::DataFrame.new({
      'timestamp' => [],
      'close_price' => []
    })

    # Create new DataFrame
    data2 = {
      'timestamp' => ['2024-11-13', '2024-11-12'],
      'close_price' => [151.0, 150.0]
    }
    df2 = SQA::DataFrame.new(data2)

    # Concatenate with deduplication
    df1.concat_and_deduplicate!(df2)

    # Should have all data from df2
    assert_equal 2, df1.nrows
    assert_equal ['2024-11-13', '2024-11-12'], df1['timestamp'].to_a
  end

  def test_concat_and_deduplicate_custom_sort_column
    # Create DataFrame with custom sort column
    data1 = {
      'id' => [3, 2, 1],
      'value' => ['c', 'b', 'a']
    }
    df1 = SQA::DataFrame.new(data1)

    # Create new DataFrame with overlapping id
    data2 = {
      'id' => [4, 3],  # 3 is duplicate
      'value' => ['d', 'c_duplicate']
    }
    df2 = SQA::DataFrame.new(data2)

    # Concatenate with deduplication on 'id'
    df1.concat_and_deduplicate!(df2, sort_column: 'id')

    # Should have 4 unique ids
    assert_equal 4, df1.nrows

    # Check descending order by id
    ids = df1['id'].to_a
    assert_equal [4, 3, 2, 1], ids
  end

  def test_concat_and_deduplicate_ascending_order
    # Create initial DataFrame
    data1 = {
      'timestamp' => ['2024-11-10', '2024-11-11', '2024-11-12'],
      'close_price' => [148.0, 149.0, 150.0]
    }
    df1 = SQA::DataFrame.new(data1)

    # Create new DataFrame
    data2 = {
      'timestamp' => ['2024-11-13', '2024-11-14'],
      'close_price' => [151.0, 152.0]
    }
    df2 = SQA::DataFrame.new(data2)

    # Concatenate with ascending order
    df1.concat_and_deduplicate!(df2, descending: false)

    # Check ascending order
    timestamps = df1['timestamp'].to_a
    assert_equal ['2024-11-10', '2024-11-11', '2024-11-12', '2024-11-13', '2024-11-14'], timestamps
  end
end
