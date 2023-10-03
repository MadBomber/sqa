# lib/sqa/data_frame/yahoo_finance.rb
# frozen_string_literal: true


class SQA::DataFrame < SQADF::DataFrame
  class YahooFinance
    CONNECTION  = Faraday.new(url: 'https://finance.yahoo.com')


    ################################################################
    #
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

      raise "NoDataError" if table.nil?

      rows      = table.css('tbody tr')

      data = []

      rows.each do |row|
        cols = row.css('td').map{|c| c.children[0].text}

        next unless 7 == cols.size
        next if cols[1]&.include?("Dividend")

        if cols.any?(nil)
          debug_me('== ERROR =='){[
            :cols
          ]}
          next
        end

        cols[0] = Date.parse(cols[0]).to_s
        cols[6] = cols[6].tr(',','').to_i
        (1..5).each {|x| cols[x] = cols[x].to_f}
        data << HEADERS.zip(cols).to_h
      end

      SQA::DataFrame.new(data)
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
