# lib/sqa/datastore/csv.rb

require 'csv'
require 'forwardable'

module SQA::Datastore
  class CSV
    extend Forwardable
    def_delegators :@data, :first, :last, :size, :empty?, :[], :map, :select, :reject

    SOURCE_DOMAIN = "https://query1.finance.yahoo.com/v7/finance/download/"
    # curl -o AAPL.csv -L --url "https://query1.finance.yahoo.com/v7/finance/download/AAPL?period1=345427200&period2=1691712000&interval=1d&events=history&includeAdjustedClose=true"


    attr_accessor :ticker
    attr_accessor :data

    def initialize(ticker, adapter = YahooFinance)
      @ticker     = ticker
      @data_path  = Pathname.pwd + "#{ticker.downcase}.csv"
      @adapter    = adapter
      @data       = adapter.load(ticker)
    end


    #######################################################################
    # Read the CSV file associated with the give ticker symbol
    #
    # def read_csv_data
    #   download_historical_prices unless @data_path.exist?

    #   csv_data = []

    #   ::CSV.foreach(@data_path, headers: true) do |row|
    #     csv_data << row.to_h
    #   end

    #   csv_data
    # end

    #######################################################################
    # download a CSV file from https://query1.finance.yahoo.com
    # given a stock ticker symbol as a String
    # start and end dates
    #
    # For ticker "aapl" the downloaded file will be named "aapl.csv"
    # That filename will be renamed to "aapl_YYYYmmdd.csv" where the
    # date suffix is the end_date of the historical data.
    #
    # def download_historical_prices(
    #       start_date: Date.new(2019, 1, 1),
    #       end_date:   previous_dow(:friday, Date.today)
    #     )

    #   start_timestamp = start_date.to_time.to_i # Convert to unix timestamp
    #   end_timestamp   = end_date.to_time.to_i

    #   user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:85.0) Gecko/20100101 Firefox/85.0"

    #   # TODO: replace curl with Faraday

    #   `curl -A "#{user_agent}" --cookie-jar cookies.txt -o #{@data_path} -L --url "#{SOURCE_DOMAIN}/#{ticker.upcase}?period1=#{start_timestamp}&period2=#{end_timestamp}&interval=1d&events=history&includeAdjustedClose=true"`

    #   check_csv_file
    # end


    # def check_csv_file
    #   f   = File.open(@data_path, 'r')
    #   c1  = f.read(1)

    #   if '{' == c1
    #     error_msg = JSON.parse("#{c1}#{f.read}")
    #     raise "Not OK: #{error_msg}"
    #   end
    # end
  end
end

__END__

{
    "finance": {
        "error": {
            "code": "Unauthorized",
            "description": "Invalid cookie"
        }
    }
}




