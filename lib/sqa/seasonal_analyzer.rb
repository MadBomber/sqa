# frozen_string_literal: true

# SQA::SeasonalAnalyzer - Detect seasonal and cyclical patterns
#
# Many stocks exhibit seasonal behavior:
# - Retail stocks: Holiday shopping (Q4)
# - Tax prep: Q1/Q4 surge
# - Energy: Summer driving season
# - Agriculture: Planting/harvest cycles
#
# This module identifies which months/quarters patterns are valid.
#
# Example:
#   seasonal = SQA::SeasonalAnalyzer.analyze(stock)
#   # => { best_months: [10, 11, 12], worst_months: [5, 6], ... }

module SQA
  module SeasonalAnalyzer
    class << self
      # Analyze seasonal performance patterns
      #
      # @param stock [SQA::Stock] Stock to analyze
      # @return [Hash] Seasonal performance metadata
      #
      def analyze(stock)
        df = stock.df

        # Extract dates and prices (handle both 'date' and 'timestamp' column names)
        date_column = df.data.columns.include?("date") ? "date" : "timestamp"
        dates = df[date_column].to_a.map { |d| Date.parse(d.to_s) }

        prices = df["adj_close_price"].to_a

        # Calculate monthly returns
        monthly_returns = calculate_monthly_returns(dates, prices)
        quarterly_returns = calculate_quarterly_returns(dates, prices)

        {
          monthly_returns: monthly_returns,
          quarterly_returns: quarterly_returns,
          best_months: rank_months(monthly_returns).first(3),
          worst_months: rank_months(monthly_returns).last(3),
          best_quarters: rank_quarters(quarterly_returns).first(2),
          worst_quarters: rank_quarters(quarterly_returns).last(2),
          has_seasonal_pattern: detect_seasonality?(monthly_returns)
        }
      end

      # Filter data by calendar months
      #
      # @param stock [SQA::Stock] Stock to analyze
      # @param months [Array<Integer>] Months to include (1-12)
      # @return [Hash] Filtered data
      #
      def filter_by_months(stock, months)
        df = stock.df

        date_column = df.data.columns.include?("date") ? "date" : "timestamp"
        dates = df[date_column].to_a.map { |d| Date.parse(d.to_s) }

        prices = df["adj_close_price"].to_a

        indices = []
        dates.each_with_index do |date, i|
          indices << i if months.include?(date.month)
        end

        {
          indices: indices,
          dates: indices.map { |i| dates[i] },
          prices: indices.map { |i| prices[i] }
        }
      end

      # Filter data by quarters
      #
      # @param stock [SQA::Stock] Stock to analyze
      # @param quarters [Array<Integer>] Quarters to include (1-4)
      # @return [Hash] Filtered data
      #
      def filter_by_quarters(stock, quarters)
        quarter_months = {
          1 => [1, 2, 3],
          2 => [4, 5, 6],
          3 => [7, 8, 9],
          4 => [10, 11, 12]
        }

        months = quarters.flat_map { |q| quarter_months[q] }
        filter_by_months(stock, months)
      end

      # Detect if stock has seasonal pattern
      #
      # @param monthly_returns [Hash] Monthly return statistics
      # @return [Boolean] True if significant seasonal pattern exists
      #
      def detect_seasonality?(monthly_returns)
        returns = monthly_returns.values.map { |stats| stats[:avg_return] }

        # Check variance in monthly returns
        mean = returns.sum / returns.size
        variance = returns.map { |r| (r - mean)**2 }.sum / returns.size
        std_dev = Math.sqrt(variance)

        # If standard deviation of monthly returns is high, likely seasonal
        std_dev > 2.0
      end

      # Get seasonal context for a specific date
      #
      # @param date [Date] Date to check
      # @return [Hash] Seasonal context
      #
      def context_for_date(date)
        {
          month: date.month,
          quarter: ((date.month - 1) / 3) + 1,
          month_name: Date::MONTHNAMES[date.month],
          quarter_name: "Q#{((date.month - 1) / 3) + 1}",
          is_year_end: [11, 12].include?(date.month),
          is_year_start: [1, 2].include?(date.month),
          is_holiday_season: [11, 12].include?(date.month),
          is_earnings_season: [1, 4, 7, 10].include?(date.month)
        }
      end

      private

      # Calculate average returns by month
      def calculate_monthly_returns(dates, prices)
        monthly_data = group_returns_by_period(dates, prices, &:month)
        build_period_stats(1..12, monthly_data)
      end

      # Calculate average returns by quarter
      def calculate_quarterly_returns(dates, prices)
        quarterly_data = group_returns_by_period(dates, prices) { |date| ((date.month - 1) / 3) + 1 }
        build_period_stats(1..4, quarterly_data)
      end

      # Group day-over-day percentage returns by a calendar period (month or
      # quarter), as derived from each day's date by the given block.
      def group_returns_by_period(dates, prices)
        period_data = Hash.new { |h, k| h[k] = [] }

        dates.each_cons(2).with_index do |(_d_1, d_2), i|
          return_pct = ((prices[i + 1] - prices[i]) / prices[i] * 100.0)
          period_data[yield(d_2)] << return_pct
        end

        period_data
      end

      # Build the avg_return/count/positive_days/negative_days stats hash
      # for every period in `period_range`, defaulting to zeros when a
      # period has no observed returns.
      def build_period_stats(period_range, period_data)
        result = {}

        period_range.each do |period|
          returns = period_data[period]
          result[period] = period_returns_stats(returns)
        end

        result
      end

      # Stats for a single period's collected returns (or zeroed defaults)
      def period_returns_stats(returns)
        return { avg_return: 0.0, count: 0, positive_days: 0, negative_days: 0 } if returns.empty?

        {
          avg_return: returns.sum / returns.size,
          count: returns.size,
          positive_days: returns.count(&:positive?),
          negative_days: returns.count(&:negative?)
        }
      end

      # Rank months by performance
      def rank_months(monthly_returns)
        monthly_returns.sort_by { |_month, stats| -stats[:avg_return] }.map(&:first)
      end

      # Rank quarters by performance
      def rank_quarters(quarterly_returns)
        quarterly_returns.sort_by { |_quarter, stats| -stats[:avg_return] }.map(&:first)
      end
    end
  end
end
