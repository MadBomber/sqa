# lib/sqa/data_frame/alpha_vantage.rb
# frozen_string_literal: true
#
# Using the Alpha Vantage JSON interface
#
require 'polars'

class SQA::DataFrame
  class AlphaVantage
    CONNECTION  = Faraday.new(url: 'https://www.alphavantage.co')
    HEADERS     = YahooFinance::HEADERS

    # The Alpha Vantage CSV format uses these exact column names:
    # timestamp, open, high, low, close, volume
    # We remap them to match Yahoo Finance column names for consistency
    HEADER_MAPPING = {
      "timestamp" => HEADERS[0],  # :timestamp (already matches, but explicit)
      "open"      => HEADERS[1],  # :open_price
      "high"      => HEADERS[2],  # :high_price
      "low"       => HEADERS[3],  # :low_price
      "close"     => HEADERS[4],  # :close_price (AND :adj_close_price - AV doesn't split these)
      "volume"    => HEADERS[6]   # :volume
    }

    # Transformers applied AFTER column renaming
    # Alpha Vantage CSV doesn't have adjusted_close, so we only transform what exists
    TRANSFORMERS  = {
      HEADERS[1] => -> (v) { v.to_f.round(3) },  # :open_price
      HEADERS[2] => -> (v) { v.to_f.round(3) },  # :high_price
      HEADERS[3] => -> (v) { v.to_f.round(3) },  # :low_price
      HEADERS[4] => -> (v) { v.to_f.round(3) },  # :close_price
      # HEADERS[5] - :adj_close_price doesn't exist in Alpha Vantage CSV
      HEADERS[6] => -> (v) { v.to_i }            # :volume
    }

    ################################################################

    # Get recent data from JSON API
    # ticker String the security to retrieve
    # returns a Polars DataFrame
    def self.recent(ticker, full: false, from_date: nil)
      response  = CONNECTION.get(
        "/query?" +
        "function=TIME_SERIES_DAILY&" +
        "symbol=#{ticker.upcase}&" +
        "apikey=#{SQA.av.key}&" +
        "datatype=csv&" +
        "outputsize=#{full ? 'full' : 'compact'}"
      ).to_hash

      unless 200 == response[:status]
        raise "Bad Response: #{response[:status]}"
      end

      # Read CSV into Polars DataFrame directly
      df = Polars.read_csv(
        StringIO.new(response[:body]),
        dtypes: {
          "open" => :f64,
          "high" => :f64,
          "low" => :f64,
          "close" => :f64,
          "volume" => :i64
        }
      )

      # Handle date criteria if applicable
      if from_date
        # Use Polars.col() to create an expression for filtering
        df = df.filter(Polars.col("timestamp") >= from_date.to_s)
      end

      # Wrap in SQA::DataFrame with proper transformers
      # Note: mapping is applied first (renames columns), then transformers
      sqa_df = SQA::DataFrame.new(df, transformers: TRANSFORMERS, mapping: HEADER_MAPPING)

      # Alpha Vantage doesn't split close/adjusted_close, so duplicate for compatibility
      # This ensures adj_close_price exists for strategies that expect it
      sqa_df.data = sqa_df.data.with_column(
        sqa_df.data["close_price"].alias("adj_close_price")
      )

      sqa_df
    end
  end
end
