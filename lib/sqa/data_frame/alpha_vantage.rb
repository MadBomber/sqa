# lib/sqa/data_frame/alpha_vantage.rb
# frozen_string_literal: true
#
# Using the Alpha Vantage JSON interface
#

require 'faraday'
require 'oj'

class SQA::DataFrame < Daru::DataFrame
  class AlphaVantage
    API_KEY     = Nenv.av_api_key
    CONNECTION  = Faraday.new(url: 'https://www.alphavantage.co')
    HEADERS     = [ # Same as YahooFinance
                    :timestamp,       # 0
                    :open_price,      # 1
                    :high_price,      # 2
                    :low_price,       # 3
                    :close_price,     # 4
                    :adj_close_price, # 5
                    :volume,          # 6
                  ]

      # The Alpha Vantage headers are being remapped so that
      # they match those of the Yahoo Finance CSV file.
      #
      HEADER_MAPPING = {
        "timestamp"       => HEADERS[0],
        "open"            => HEADERS[1],
        "high"            => HEADERS[2],
        "low"             => HEADERS[3],
        "close"           => HEADERS[4],
        "adjusted_close"  => HEADERS[5],
        "volume"          => HEADERS[6]
      }

      JSON_HEADER_MAPPING = {
        "timestamp"       => HEADERS[0],
        "open"            => HEADERS[1],
        "high"            => HEADERS[2],
        "low"             => HEADERS[3],
        "close"           => HEADERS[4],
        "adjusted_close"  => HEADERS[5],
        "volume"          => HEADERS[6]
      }


    ################################################################
    def self.load(filename, options={}, &block)

      # TODO: If CSV file does not exists, get a full JSON dump from
      #       Alpha Vantage, create the dataframe, then dump the
      #       dataframe to a CSV file.
      #
      begin
        df = SQA::DataFrame.load(filename, options={}, &block)
      rescue => e
        debug_me{[ :e ]}
        # SMELL: what if its a bad ticker symbol?
        df = recent(ticker, full: true)
        df.to_csv
      end

      headers = df.vectors

      # convert vector names to symbols
      # when they are strings.
      if headers.first == HEADERS.first.to_s
        a_hash = {}
        HEADERS.each {|k| a_hash[k.to_s] = k}
        df.rename_vectors(a_hash)
      else
        df.rename_vectors(HEADER_MAPPING)
      end

      df
    end


    # Get recent data from JSON API
    #
    # ticker String the security to retrieve
    # returns a DataFrame
    #
    def self.recent(ticker, full: false)
      response  = CONNECTION.get(
        "/query?function=TIME_SERIES_DAILY_ADJUSTED&symbol=#{ticker.upcase}&apikey=#{API_KEY}&datatype=json&outputsize=#{full ? 'full' : 'compact'}"
      )

      data = []

      # rows.each do |row|
      #   cols = row.css('td').map{|c| c.children[0].text}

      #   # next unless 7 == cols.size
      #   # next if cols[1]&.include?("Dividend")

      #   if cols.any?(nil)
      #     debug_me('== ERROR =='){[
      #       :cols
      #     ]}
      #     next
      #   end

      #   cols[0] = Date.parse(cols[0]).to_s
      #   cols[6] = cols[6].tr(',','').to_i
      #   (1..5).each {|x| cols[x] = cols[x].to_f}
      #   data << HEADERS.zip(cols).to_h
      # end

      Daru::DataFrame.new(data)
    end


    # Append update_df rows to the base_df
    #
    # base_df is ascending on timestamp
    # update_df is descending on timestamp
    #
    # base_df content came from CSV file downloaded
    # from Yahoo Finance.
    #
    # update_df came from scraping the webpage
    # at Yahoo Finance for the recent history.
    #
    # Returns a combined DataFrame.
    #
    def self.append(base_df, updates_df)
      last_timestamp  = Date.parse base_df.timestamp.last
      filtered_df     = updates_df.filter_rows { |row| Date.parse(row[:timestamp]) > last_timestamp }

      last_inx = filtered_df.size - 1

      (0..last_inx).each do |x|
        base_df.add_row filtered_df.row[last_inx-x]
      end

      base_df
    end
  end
end
