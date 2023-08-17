# libsvm File Format

This file format is used by rumale.

We're choosing the "Adj Close" column as the one that we want to predict.

The libsvm file format is simple.  All values are numberic.

The first entry on a line is the thing that we want to predict.  In this case it is the adjusted closing price.  This is followed by a space.

What follows is a series of data pairs seperated by spaces in the form:

* index:value

where index is the column number and value is the value for that item.


```ruby
require 'csv'

# Read CSV file
data = CSV.read('input.csv', headers: true)

# Open output file
output_file = File.open('output.txt', 'w')

# Convert data into libsvm format and write to output file
data.each do |row|
  # Get the label (the "close" value)
  label = row['Adj Close']

  # Start building the libsvm formatted line
  libsvm_line = "#{label} "

  # Add feature indices and values
  row.each_with_index do |(column, value), index|
    next if column == 'Date' || column == 'Adj Close' # Skip irrelevant columns
    libsvm_line += "#{index}:#{value} "
  end

  # Write the libsvm formatted line to the output file
  output_file.puts(libsvm_line)
end

# Close files
output_file.close
```
