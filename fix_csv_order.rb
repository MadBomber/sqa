#!/usr/bin/env ruby
# Script to fix CSV file ordering from descending to ascending

require_relative 'lib/sqa'
require 'polars'

SQA.init

data_dir = SQA.data_dir
puts "=" * 70
puts "CSV Order Fix Script"
puts "=" * 70
puts "Data directory: #{data_dir}"
puts

# Find all CSV files
csv_files = Dir.glob("#{data_dir}/*.csv")

if csv_files.empty?
  puts "No CSV files found in #{data_dir}"
  exit 0
end

puts "Found #{csv_files.size} CSV file(s)"
puts

csv_files.each do |file|
  ticker = File.basename(file, '.csv')
  puts "Processing: #{ticker.upcase}"

  begin
    # Read CSV
    df = Polars.read_csv(file)

    # Get first and last timestamps
    timestamps = df["timestamp"].to_a
    first_date = Date.parse(timestamps.first)
    last_date = Date.parse(timestamps.last)

    if first_date < last_date
      puts "  ✅ Already in ascending order (oldest-first) - skipping"
    else
      puts "  ⚠️  In descending order (newest-first) - fixing..."

      # Remove duplicates
      df = df.unique(subset: ["timestamp"], keep: "first")
      puts "     - Removed duplicates (if any)"

      # Sort ascending
      df = df.sort("timestamp", reverse: false)
      puts "     - Sorted to ascending order"

      # Backup original
      backup_file = "#{file}.backup.#{Time.now.to_i}"
      File.rename(file, backup_file)
      puts "     - Backed up to: #{File.basename(backup_file)}"

      # Save fixed version
      df.write_csv(file)
      puts "     ✅ Fixed and saved"

      # Verify
      df_verify = Polars.read_csv(file)
      ts_verify = df_verify["timestamp"].to_a
      first_verify = Date.parse(ts_verify.first)
      last_verify = Date.parse(ts_verify.last)

      if first_verify < last_verify
        puts "     ✅ Verification passed"
      else
        puts "     ❌ Verification failed - restoring backup"
        File.rename(backup_file, file)
      end
    end
  rescue => e
    puts "  ❌ Error: #{e.message}"
  end

  puts
end

puts "=" * 70
puts "Done!"
puts
puts "To test, run:"
puts "  ruby debug_csv_order.rb TICKER"
puts
puts "Backup files can be deleted once verified:"
puts "  rm #{data_dir}/*.backup.*"
puts "=" * 70
