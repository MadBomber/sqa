# lib/sqa/data_frame/yahoo_finance.rb
# frozen_string_literal: true

require 'polars'

=begin
  The website financial.yahoo.com no longer supports an API.
  To get recent stock historical price updates you have
  to scrape the webpage.
=end

class SQA::DataFrame
  class YahooFinance
    CONNECTION  = Faraday.new(url: 'https://finance.yahoo.com')
    HEADERS     = [
                    :timestamp,       # 0
                    :open_price,      # 1
                    :high_price,      # 2
                    :low_price,       # 3
                    :close_price,     # 4
                    :adj_close_price, # 5
                    :volume,          # 6
                  ]

    HEADER_MAPPING = {
      "Date"      => HEADERS[0],
      "Open"      => HEADERS[1],
      "High"      => HEADERS[2],
      "Low"       => HEADERS[3],
      "Close"     => HEADERS[4],
      "Adj Close" => HEADERS[5],
      "Volume"    => HEADERS[6]
    }

    ################################################################

    # Scrape the Yahoo Finance website to get recent
    # historical prices for a specific ticker
    # returns a Polars DataFrame
    def self.recent(ticker)
      response = CONNECTION.get("/quote/#{ticker.upcase}/history")
      doc = Nokogiri::HTML(response.body)
      table = doc.css('table').first

      raise "NoDataError" if table.nil?

      rows = table.css('tbody tr')

      data = rows.map do |row|
        cols = row.css('td').map { |c| c.children[0].text }

        next unless cols.size == 7
        next if cols[1]&.include?("Dividend")
        next if cols.any?(nil)

        {
          "Date"      => Date.parse(cols[0]).to_s,
          "Open"      => cols[1].to_f,
          "High"      => cols[2].to_f,
          "Low"       => cols[3].to_f,
          "Close"     => cols[4].to_f,
          "Adj Close" => cols[5].to_f,
          "Volume"    => cols[6].tr(',', '').to_i
        }
      end.compact

      # Utilize Polars DataFrame for the Yahoo Finance data
      Polars::DataFrame.new(data)
    end
  end
end

