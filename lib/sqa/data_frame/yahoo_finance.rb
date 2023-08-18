# lib/sqa/data_frame/yahoo_finance.rb
# frozen_string_literal: true

class SQA::DataFrame < Daru::DataFrame
  class YahooFinance
    def self.load(filename, options={}, &block)
      df = SQA::DataFrame.load(filename, options={}, &block)

      # ASSUMPTION: This is the column headers from Yahoo Finance for
      # CSV files.  If the file type is something different from the
      # same source, they may not be the same.
      #
      new_names = {
        "Date"      => :timestamp,
        "Open"      => :open_price,
        "High"      => :high_price,
        "Low"       => :low_price,
        "Close"     => :close_price,
        "Adj Close" => :adj_close_price,
        "Volume"    => :volume
      }

      df.rename_vectors(new_names)

      df
    end
  end
end
