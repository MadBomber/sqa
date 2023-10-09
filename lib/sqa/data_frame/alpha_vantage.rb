# lib/sqa/data_frame/alpha_vantage.rb
# frozen_string_literal: true
#
# Using the Alpha Vantage JSON interface
#


class SQA::DataFrame
  class AlphaVantage
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
    def self.recent(ticker, full: false, from_date: nil)

      # NOTE: Using the CSV format because the JSON format has
      #       really silly key values.  The column names for the
      #       CSV format are much better.
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

      raw           = response[:body].split
      headers       = raw.shift.split(',')

      headers[0]    = 'date'  # website returns "timestamp" but that
                              # has an unintended side-effect when
                              # the names are normalized.
                              # SMELL: IS THIS STILL TRUE?

      close_inx     = headers.size - 2
      adj_close_inx = close_inx + 1

      headers.insert(adj_close_inx, 'adjusted_close')

      aofh    = raw.map do |e|
                  e2 = e.split(',')
                  e2[1..-2] = e2[1..-2].map(&:to_f) # converting open, high, low, close
                  e2[-1]    = e2[-1].to_i           # converting volumn
                  e2.insert(adj_close_inx, e2[close_inx]) # duplicate the close price as a fake adj close price
                  headers.zip(e2).to_h
                end

      if from_date
        aofh.reject!{|e| Date.parse(e['date']) < from_date}
      end

      return nil if aofh.empty?

      # ensure tha the data frame is
      # always sorted oldest to newest.

      if aofh.first['date'] > aofh.last['date']
        aofh.reverse!
      end

      SQA::DataFrame.from_aofh(aofh, mapping: HEADER_MAPPING, transformers: TRANSFORMERS)
    end
  end
end
