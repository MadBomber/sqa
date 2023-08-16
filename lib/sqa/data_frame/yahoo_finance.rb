# lib/sqa/data_frame/yahoo_finance.rb
# frozen_string_literal: true

class SQA::DataFrame < Daru::DataFrame
  class YahooFinance
    def self.from_csv(ticker)
      df = SQA::DataFrame.from_csv(ticker)

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
