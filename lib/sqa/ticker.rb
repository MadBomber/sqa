# sqa/lib/sqa/ticker.rb
#
# Uses the https://dumbstockapi.com/ website to download a CSV file
#
# The CSV files have names like this:
#   "dumbstockapi-2023-09-21T16 39 55.165Z.csv"
#
# which has this header:
#   ticker,name,is_etf,exchange
#
# Not using the is_etf columns
#
class SQA::Ticker
  FILENAME_PREFIX = "dumbstockapi"
  CONNECTION      = Faraday.new(url: "https://dumbstockapi.com")

  class << self
    def download(country="US")
      response = CONNECTION.get("/stock?format=csv&countries=#{country.upcase}").to_hash

      if 200 == response[:status]
        filename = response[:response_headers]["content-disposition"].split('=').last.gsub('"','')
        out_path = Pathname.new(SQA.config.data_dir) + filename
        out_path.write response[:body]
      end

      response[:status]
    end

    def load
      tries = 0
      found = false

      until(found || tries >= 3) do
        files     = Pathname.new(SQA.config.data_dir).children.select{|c| c.basename.to_s.start_with?(FILENAME_PREFIX)}.sort
        if files.empty?
          begin
            download
          rescue StandardError => e
            warn "Warning: Could not download ticker list: #{e.message}" if $VERBOSE
          end
          tries += 1
        else
          found = true
        end
      end

      if files.empty?
        warn "Warning: No ticker validation data available. Proceeding without validation." if $VERBOSE
        return {}
      end

      load_from_csv files.last
    end

    def load_from_csv(csv_path)
      @data ||= {}
      CSV.foreach(csv_path, headers: true) do |row|
        @data[row["ticker"]] = {
          name:     row["name"],
          exchange: row["exchange"]
        }
      end

      @data
    end

    def data
      @data ||= {}
      @data.empty? ? load : @data
    end

    def lookup(ticker)
      return nil if ticker.nil? || ticker.to_s.empty?
      data[ticker.to_s.upcase]
    end

    def valid?(ticker)
      return false if ticker.nil? || ticker.to_s.empty?
      data.key?(ticker.to_s.upcase)
    end

    # Reset cached data (useful for testing)
    def reset!
      @data = {}
    end
  end
end
