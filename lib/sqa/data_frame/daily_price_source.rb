# lib/sqa/data_frame/daily_price_source.rb
# frozen_string_literal: true

#
# Shared .recent(ticker, full:, from_date:) template for daily-price sources
# (Stooq, FMP) that don't provide a distinct split/dividend-adjusted close
# and support a compact/full/from_date fetch window. `extend` this and
# provide:
#   - a COMPACT_DAYS constant (calendar days requested for a compact fetch)
#   - a private .fetch_dataframe(ticker, start_date:) class method
#
class SQA::DataFrame
  module DailyPriceSource
    # Get recent daily data.
    #
    # ticker    String  the security to retrieve
    # full      Boolean whether to fetch full available history (true) or
    #                   just the last COMPACT_DAYS days (false)
    # from_date Date    optional; fetch data strictly AFTER this date (for
    #                   incremental updates). Overrides the compact window.
    #
    # Returns: SQA::DataFrame sorted ASCENDING (oldest to newest) for TA-Lib.
    def recent(ticker, full: false, from_date: nil)
      start_date =
        if from_date
          from_date
        elsif full
          nil
        else
          Date.today - self::COMPACT_DAYS
        end

      sqa_df = fetch_dataframe(ticker, start_date: start_date)
      data   = sqa_df.data

      # Exclude the from_date itself (> not >=) so an incremental update that
      # overlaps the last cached day doesn't reintroduce a duplicate row.
      data = data.filter(Polars.col("timestamp") > from_date.to_s) if from_date

      # No adjusted close from this source; duplicate close_price so that
      # strategies expecting :adj_close_price keep working.
      data = data.with_columns(data["close_price"].alias("adj_close_price"))

      # Defensive: guarantee ascending (oldest-first) order for TA-Lib.
      sqa_df.data = data.sort("timestamp", descending: false)

      sqa_df
    end
  end
end
