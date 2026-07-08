# sqa/lib/sqa/init.rb

# SQA (Simple Qualitative Analysis) - Ruby library for stock market technical analysis.
# Provides high-performance data structures, trading strategies, and integrates with
# the sqa-tai gem for 150+ technical indicators.
#
# @example Basic usage
#   require 'sqa'
#   SQA.init
#   stock = SQA::Stock.new(ticker: 'AAPL')
#   prices = stock.df["adj_close_price"].to_a
#
# @example With configuration
#   SQA.init
#   SQA.config.data_dir = "~/my_data"
#   SQA.config.lazy_update = true
#
module SQA
  class << self
    # @!attribute [w] config
    #   @return [SQA::Config] Configuration instance
    attr_writer :config

    # Initializes the SQA library.
    # Should be called once at application startup.
    #
    # @param argv [Array<String>, String] Command line arguments (default: ARGV)
    # @return [SQA::Config] The configuration instance
    #
    # @example
    #   SQA.init
    #   SQA.init("--debug --verbose")
    #
    def init(argv = ARGV)
      if argv.is_a? String
        argv.split
      end

      # Ran at SQA::Config elaboration time
      # @config = Config.new

      # If there's no CLI defined, there are no real command line parameters
      # because the sqa gem is being required within the context of a larger program.
      CLI.run! if defined? CLI    # CLI handles its own argument parsing

      config.data_dir = homify(config.data_dir)

      config
    end

    # Returns the Alpha Vantage API key.
    # Reads from AV_API_KEY or ALPHAVANTAGE_API_KEY environment variables.
    #
    # @return [String] The API key
    # @raise [SQA::ConfigurationError] If no API key is set
    def av_api_key
      @av_api_key ||= ENV['AV_API_KEY'] || ENV.fetch('ALPHAVANTAGE_API_KEY', nil)
      @av_api_key || raise(SQA::ConfigurationError,
                           'Alpha Vantage API key not set. Set AV_API_KEY or ALPHAVANTAGE_API_KEY environment variable.')
    end

    # Sets the Alpha Vantage API key.
    #
    # @param key [String] The API key to set
    # @return [String] The key that was set
    def av_api_key=(key)
      @av_api_key = key
    end

    # Legacy accessor for backward compatibility with SQA.av.key usage.
    #
    # @return [SQA] Self, to allow SQA.av.key calls
    def av
      self
    end

    # Returns the API key for compatibility with old SQA.av.key usage.
    #
    # @return [String] The API key
    # @raise [SQA::ConfigurationError] If no API key is set
    def key
      av_api_key
    end

    # Returns the Financial Modeling Prep (FMP) API key.
    # Reads from the FMP_API_KEY environment variable (env-only, like the
    # Alpha Vantage key). Used by SQA::FMP for company fundamentals.
    #
    # @return [String] The FMP API key
    # @raise [SQA::ConfigurationError] If no API key is set
    def fmp_api_key
      @fmp_api_key ||= ENV.fetch('FMP_API_KEY', nil)
      @fmp_api_key || raise(SQA::ConfigurationError,
                            'FMP API key not set. Set FMP_API_KEY environment variable.')
    end

    # Sets the Financial Modeling Prep API key.
    #
    # @param key [String] The API key to set
    # @return [String] The key that was set
    def fmp_api_key=(key)
      @fmp_api_key = key
    end

    # Returns whether debug mode is enabled.
    # @return [Boolean] true if debug mode is on
    def debug? 						= @config&.debug?

    # Returns whether verbose mode is enabled.
    # @return [Boolean] true if verbose mode is on
    def verbose? 					= @config&.verbose?

    # Expands ~ to user's home directory in filepath.
    #
    # @param filepath [String] Path potentially containing ~
    # @return [String] Path with ~ expanded
    def homify(filepath) 		= filepath.gsub(/^~/, Nenv.home)

    # Returns the data directory as a Pathname.
    #
    # @return [Pathname] Data directory path
    def data_dir 					= Pathname.new(config.data_dir)

    # Returns the current configuration.
    #
    # @return [SQA::Config] Configuration instance
    def config            = @config
  end
end
