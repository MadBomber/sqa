# lib/sqa/data_frame/yahoo_finance.rb
# frozen_string_literal: true

require 'polars'

#   The website financial.yahoo.com no longer supports an API.
#   To get recent stock historical price updates you have
#   to scrape the webpage.

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
      :volume          # 6
    ].freeze

    HEADER_MAPPING = {
      "Date"      => HEADERS[0],
      "Open"      => HEADERS[1],
      "High"      => HEADERS[2],
      "Low"       => HEADERS[3],
      "Close"     => HEADERS[4],
      "Adj Close" => HEADERS[5],
      "Volume"    => HEADERS[6]
    }.freeze

    ################################################################

    # Scrape the Yahoo Finance website to get recent
    # historical prices for a specific ticker
    # returns a Polars DataFrame
    def self.recent(ticker)
      table = fetch_history_table(ticker)
      data = table.css('tbody tr').map { |row| parse_history_row(row) }.compact

      # Create Polars DataFrame then wrap in SQA::DataFrame
      polars_df = Polars::DataFrame.new(data)
      SQA::DataFrame.new(polars_df, mapping: HEADER_MAPPING)
    end

    # Fetch and parse the Yahoo Finance history page for `ticker`,
    # returning the first data table found.
    def self.fetch_history_table(ticker)
      response = CONNECTION.get("/quote/#{ticker.upcase}/history")
      doc = Nokogiri::HTML(response.body)
      table = doc.css('table').first

      raise "NoDataError" if table.nil?

      table
    end
    private_class_method :fetch_history_table

    # Parse a single history table row into a Yahoo-column-named Hash,
    # or nil if the row should be skipped (malformed, or a dividend entry).
    def self.parse_history_row(row)
      cols = row.css('td').map { |c| c.children[0].text }

      return nil unless cols.size == 7
      return nil if cols[1]&.include?("Dividend")
      return nil if cols.any?(nil)

      {
        "Date"      => Date.parse(cols[0]).to_s,
        "Open"      => cols[1].to_f,
        "High"      => cols[2].to_f,
        "Low"       => cols[3].to_f,
        "Close"     => cols[4].to_f,
        "Adj Close" => cols[5].to_f,
        "Volume"    => cols[6].tr(',', '').to_i
      }
    end
    private_class_method :parse_history_row
  end
end
