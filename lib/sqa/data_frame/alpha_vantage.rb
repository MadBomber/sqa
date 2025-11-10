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

    # The Alpha Vantage headers are being remapped so that
    # they match those of the Yahoo Finance CSV file.
    HEADER_MAPPING = {
      "date"            => HEADERS[0],
      "open"            => HEADERS[1],
      "high"            => HEADERS[2],
      "low"             => HEADERS[3],
      "close"           => HEADERS[4],
      "adjusted_close"  => HEADERS[5],
      "volume"          => HEADERS[6]
    }

    TRANSFORMERS  = {
      HEADERS[1] => -> (v) { v.to_f.round(3) },
      HEADERS[2] => -> (v) { v.to_f.round(3) },
      HEADERS[3] => -> (v) { v.to_f.round(3) },
      HEADERS[4] => -> (v) { v.to_f.round(3) },
      HEADERS[5] => -> (v) { v.to_f.round(3) },
      HEADERS[6] => -> (v) { v.to_i }
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
        df = df.filter(df["date"].gt_eq(from_date.to_s))
      end

      # Relay that DataFrame
      df
    end
  end
end
