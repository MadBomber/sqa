# lib/sqa/data_frame/alpha_vantage.rb
# frozen_string_literal: true
#
# Using the Alpha Vantage JSON interface
#

require 'faraday'
require 'json'

class SQA::DataFrame < Daru::DataFrame
  class AlphaVantage
    API_KEY     = Nenv.av_api_key
    CONNECTION  = Faraday.new(url: 'https://www.alphavantage.co')
    HEADERS     = YahooFinance::HEADERS

    # The Alpha Vantage headers are being remapped so that
    # they match those of the Yahoo Finance CSV file.
    #
    HEADER_MAPPING = {
      "date"            => HEADERS[0],
      "open"            => HEADERS[1],
      "high"            => HEADERS[2],
      "low"             => HEADERS[3],
      "close"           => HEADERS[4],
      "adjusted_close"  => HEADERS[5],
      "volume"          => HEADERS[6]
    }


    ################################################################
    # Load a Dataframe from a csv file
    def self.load(ticker, type="csv")
      filepath = SQA.data_dir + "#{ticker}.#{type}"

      if filepath.exist?
        df = normalize_vector_names SQA::DataFrame.load(ticker, type)
      else
        df = recent(ticker, full: true)
        df.send("to_#{type}",filepath)
      end

      df
    end


    # Normalize the vector (aka column) names as
    # symbols using the standard names set by
    # Yahoo Finance ... since it was the first one
    # not because its anything special.
    #
    def self.normalize_vector_names(df)
      headers = df.vectors.to_a

      # convert vector names to symbols
      # when they are strings.  They become stings
      # when the data frame is saved to a CSV file
      # and then loaded back in.

      if headers.first == HEADERS.first.to_s
        a_hash = {}
        HEADERS.each {|k| a_hash[k.to_s] = k}
        df.rename_vectors(a_hash) # renames from String to Symbol
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
    # NOTE: The function=TIME_SERIES_DAILY_ADJUSTED
    #       is not a free API endpoint from Alpha Vantange.
    #       So we are just using the free API endpoint
    #       function=TIME_SERIES_DAILY
    #       This means that we are not getting the
    #       real adjusted closing price.  To sync
    #       the columns with those from Yahoo Finance
    #       we are duplicating the unadjusted clossing price
    #       and adding that to the data frame as if it were
    #       adjusted.
    #
    def self.recent(ticker, full: false)
      # NOTE: Using the CSV format because the JSON format has
      #       really silly key values.  The column names for the
      #       CSV format are much better.
      response  = CONNECTION.get(
        "/query?" +
        "function=TIME_SERIES_DAILY&" +
        "symbol=#{ticker.upcase}&" +
        "apikey=#{API_KEY}&" +
        "datatype=csv&" +
        "outputsize=#{full ? 'full' : 'compact'}"
      ).to_hash

      unless 200 == response[:status]
        raise "Bad Response: #{response[:status]}"
      end

      raw           = response[:body].split

      headers       = raw.shift.split(',')
      headers[0]    = 'date'  # website returns "timestamp" but that
                              # has an unintended side-effect when
                              # the names are normalized.

      close_inx     = headers.size - 2
      adj_close_inx = close_inx + 1

      headers.insert(adj_close_inx, 'adjusted_close')

      data    = raw.map do |e|
                  e2 = e.split(',')
                  e2[1..-2] = e2[1..-2].map(&:to_f) # converting open, high, low, close
                  e2[-1]    = e2[-1].to_i           # converting volumn
                  e2.insert(adj_close_inx, e2[close_inx]) # duplicate the close price as a fake adj close price
                  headers.zip(e2).to_h
                end

      # What oldest data first in the data frame
      normalize_vector_names Daru::DataFrame.new(data.reverse)
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
