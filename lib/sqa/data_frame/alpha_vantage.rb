# lib/sqa/data_frame/alpha_vantage.rb
# frozen_string_literal: true

#
# Using the Alpha Vantage JSON interface
#
require 'polars'

class SQA::DataFrame
  class AlphaVantage
    CONNECTION  = Faraday.new(url: 'https://www.alphavantage.co')
    HEADERS     = YahooFinance::HEADERS

    # The Alpha Vantage CSV format uses these exact column names:
    # timestamp, open, high, low, close, volume
    # We remap them to match Yahoo Finance column names for consistency
    HEADER_MAPPING = {
      "timestamp" => HEADERS[0],  # :timestamp (already matches, but explicit)
      "open"      => HEADERS[1],  # :open_price
      "high"      => HEADERS[2],  # :high_price
      "low"       => HEADERS[3],  # :low_price
      "close"     => HEADERS[4],  # :close_price (AND :adj_close_price - AV doesn't split these)
      "volume"    => HEADERS[6]   # :volume
    }.freeze

    # Transformers applied AFTER column renaming
    # Alpha Vantage CSV doesn't have adjusted_close, so we only transform what exists
    TRANSFORMERS  = {
      HEADERS[1] => ->(v) { v.to_f.round(3) },  # :open_price
      HEADERS[2] => ->(v) { v.to_f.round(3) },  # :high_price
      HEADERS[3] => ->(v) { v.to_f.round(3) },  # :low_price
      HEADERS[4] => ->(v) { v.to_f.round(3) },  # :close_price
      # HEADERS[5] - :adj_close_price doesn't exist in Alpha Vantage CSV
      HEADERS[6] => lambda(&:to_i)            # :volume
    }.freeze

    ################################################################

    # Get recent data from Alpha Vantage API
    #
    # ticker String the security to retrieve
    # full Boolean whether to fetch full history or compact (last 100 days)
    # from_date Date optional date to fetch data after (for incremental updates)
    #
    # Returns: SQA::DataFrame sorted in ASCENDING order (oldest to newest)
    # Note: Alpha Vantage returns data newest-first, but we sort ascending for TA-Lib compatibility
    def self.recent(ticker, full: false, from_date: nil)
      sqa_df = begin
        fetch_dataframe(ticker, full: full)
      rescue ApiError => e
        raise unless full && premium_outputsize_error?(e.message)

        # Free-tier keys can't use outputsize=full anymore (Alpha Vantage
        # made it a premium-only feature). Fall back to compact (~100
        # trading days) rather than failing outright.
        if $VERBOSE
          warn "Note: outputsize=full requires a premium Alpha Vantage plan; " \
               "using compact (~100 trading days) for #{ticker} instead."
        end
        fetch_dataframe(ticker, full: false)
      end

      # Handle date criteria if applicable
      if from_date
        # Use Polars.col() to create an expression for filtering
        # Use > (not >=) to exclude the from_date itself and prevent duplicates
        sqa_df.data = sqa_df.data.filter(Polars.col("timestamp") > from_date.to_s)
      end

      # Alpha Vantage doesn't split close/adjusted_close, so duplicate for compatibility
      # This ensures adj_close_price exists for strategies that expect it
      sqa_df.data = sqa_df.data.with_columns(
        sqa_df.data["close_price"].alias("adj_close_price")
      )

      # Sort data in ascending chronological order (oldest to newest) for TA-Lib compatibility
      # Alpha Vantage returns data newest-first, but TA-Lib expects oldest-first
      sqa_df.data = sqa_df.data.sort("timestamp", descending: false)

      sqa_df
    end

    # Fetches one page of daily price CSV from Alpha Vantage and wraps it as
    # an SQA::DataFrame. Raises ApiError if Alpha Vantage responds with a
    # JSON error body instead of CSV (rate limit, bad symbol, premium-only
    # feature, etc.).
    def self.fetch_dataframe(ticker, full:)
      response = CONNECTION.get(
        "/query?" \
        "function=TIME_SERIES_DAILY&" \
        "symbol=#{ticker.upcase}&" \
        "apikey=#{SQA.av.key}&" \
        "datatype=csv&" \
        "outputsize=#{full ? 'full' : 'compact'}"
      ).to_hash

      unless response[:status] == 200
        raise "Bad Response: #{response[:status]}"
      end

      # Alpha Vantage reports rate limits / bad symbols as a JSON body even
      # when datatype=csv was requested. Detect that before handing it to
      # the CSV parser, which would otherwise misparse it as garbage data
      # and fail later with a confusing Polars column error.
      if response[:body].lstrip.start_with?('{')
        parsed = JSON.parse(response[:body])
        ApiError.raise(parsed['Information'] || parsed['Note'] || response[:body])
      end

      # Read CSV into Polars DataFrame directly
      # schema_overrides values must be Ruby classes (Float/Integer) or Polars
      # dtype instances -- this polars-df version's Utils.parse_rb_type_into_dtype
      # doesn't accept the old :f64/:i64 symbol shorthand.
      df = Polars.read_csv(
        StringIO.new(response[:body]),
        schema_overrides: {
          "open" => Float,
          "high" => Float,
          "low" => Float,
          "close" => Float,
          "volume" => Integer
        }
      )

      # Wrap in SQA::DataFrame with proper transformers
      # Note: mapping is applied first (renames columns), then transformers
      SQA::DataFrame.new(df, transformers: TRANSFORMERS, mapping: HEADER_MAPPING)
    end
    private_class_method :fetch_dataframe

    # True if the Alpha Vantage error message is specifically about
    # outputsize=full requiring a premium plan (as opposed to a rate limit,
    # invalid symbol, or other error we shouldn't silently swallow).
    def self.premium_outputsize_error?(message)
      message.include?('outputsize=full') && message.include?('premium')
    end
    private_class_method :premium_outputsize_error?
  end
end
