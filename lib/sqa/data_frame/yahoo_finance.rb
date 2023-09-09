# lib/sqa/data_frame/yahoo_finance.rb
# frozen_string_literal: true

require 'faraday'
require 'nokogiri'

class SQA::DataFrame < Daru::DataFrame
  class YahooFinance
    CONNECTION  = Faraday.new(url: 'https://finance.yahoo.com')
    HEADERS     = [
                    :timestamp,       # 0
                    :open_price,      # 1
                    :high_price,      # 2
                    :low_price,       # 3
                    :close_price,     # 4
                    :adj_close_price, # 5
                    :volume           # 6
                  ]


    ################################################################
    def self.load(filename, options={}, &block)
      df = SQA::DataFrame.load(filename, options={}, &block)

      # ASSUMPTION: This is the column headers from Yahoo Finance for
      # CSV files.  If the file type is something different from the
      # same source, they may not be the same.
      #
      new_names = {
        "Date"      => HEADERS[0],
        "Open"      => HEADERS[1],
        "High"      => HEADERS[2],
        "Low"       => HEADERS[3],
        "Close"     => HEADERS[4],
        "Adj Close" => HEADERS[5],
        "Volume"    => HEADERS[6]
      }

      df.rename_vectors(new_names)

      df
    end


    # Scrape the Yahoo Finance website to get recent
    # historical prices for a specific ticker
    #
    # ticker String the security to retrieve
    # returns a DataFrame
    #
    def self.recent(ticker)
      response  = CONNECTION.get("/quote/#{ticker.upcase}/history")
      doc       = Nokogiri::HTML(response.body)
      table     = doc.css('table').first
      rows      = table.css('tbody tr')

      data = []

      rows.each do |row|
        cols = row.css('td').map{|c| c&.text}
        next if cols[1]&.include?("Dividend")
        cols[0] = Date.parse(cols[0]).to_s
        cols[6] = cols[6].tr(',','').to_i
        (1..5).each {|x| cols[x] = cols[x].to_f}
        data << HEADERS.zip(cols).to_h
      end

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
