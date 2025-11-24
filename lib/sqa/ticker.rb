# sqa/lib/sqa/ticker.rb
#
# Stock ticker symbol validation and lookup using the dumbstockapi.com service.
# Downloads and caches a CSV file containing ticker symbols, company names, and exchanges.
#
# @example Validating a ticker
#   SQA::Ticker.valid?('AAPL')  # => true
#   SQA::Ticker.valid?('FAKE')  # => false
#
# @example Looking up ticker info
#   info = SQA::Ticker.lookup('AAPL')
#   info[:name]      # => "Apple Inc"
#   info[:exchange]  # => "NASDAQ"
#
class SQA::Ticker
  # @return [String] Prefix for downloaded CSV filenames
  FILENAME_PREFIX = "dumbstockapi"

  # @return [Faraday::Connection] Connection to dumbstockapi.com
  CONNECTION      = Faraday.new(url: "https://dumbstockapi.com")

  class << self
    # Downloads ticker data from dumbstockapi.com and saves to data directory.
    #
    # @param country [String] Country code for ticker list (default: "US")
    # @return [Integer] HTTP status code from the download request
    #
    # @example
    #   SQA::Ticker.download("US")  # => 200
    #
    def download(country="US")
      response = CONNECTION.get("/stock?format=csv&countries=#{country.upcase}").to_hash

      if 200 == response[:status]
        filename = response[:response_headers]["content-disposition"].split('=').last.gsub('"','')
        out_path = Pathname.new(SQA.config.data_dir) + filename
        out_path.write response[:body]
      end

      response[:status]
    end

    # Loads ticker data from cached CSV or downloads if not available.
    # Retries download up to 3 times if no cached file exists.
    #
    # @return [Hash{String => Hash}] Hash mapping ticker symbols to info hashes
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

    # Loads ticker data from a specific CSV file.
    #
    # @param csv_path [Pathname, String] Path to CSV file
    # @return [Hash{String => Hash}] Hash mapping ticker symbols to info hashes
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

    # Returns the cached ticker data, loading it if necessary.
    #
    # @return [Hash{String => Hash}] Hash mapping ticker symbols to info hashes
    def data
      @data ||= {}
      @data.empty? ? load : @data
    end

    # Looks up information for a specific ticker symbol.
    #
    # @param ticker [String, nil] Ticker symbol to look up
    # @return [Hash, nil] Hash with :name and :exchange keys, or nil if not found
    #
    # @example
    #   SQA::Ticker.lookup('AAPL')  # => { name: "Apple Inc", exchange: "NASDAQ" }
    #   SQA::Ticker.lookup('FAKE')  # => nil
    #
    def lookup(ticker)
      return nil if ticker.nil? || ticker.to_s.empty?
      data[ticker.to_s.upcase]
    end

    # Checks if a ticker symbol is valid (exists in the data).
    #
    # @param ticker [String, nil] Ticker symbol to validate
    # @return [Boolean] true if ticker exists, false otherwise
    #
    # @example
    #   SQA::Ticker.valid?('AAPL')  # => true
    #   SQA::Ticker.valid?(nil)     # => false
    #
    def valid?(ticker)
      return false if ticker.nil? || ticker.to_s.empty?
      data.key?(ticker.to_s.upcase)
    end

    # Resets the cached ticker data.
    # Useful for testing to force a fresh load.
    #
    # @return [Hash] Empty hash
    def reset!
      @data = {}
    end
  end
end
