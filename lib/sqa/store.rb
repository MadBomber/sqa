# lib/sqa/store.rb
# frozen_string_literal: true

require_relative 'store/base'
require_relative 'store/market'
require_relative 'store/portfolio'
require_relative 'store/importer'

module SQA
  # SQLite-backed persistence for SQA, split across two database files.
  #
  # The split is along a single axis — whether the data can be re-fetched:
  #
  # - **`sqa.db`** ({Market}) holds stock metadata, daily price history, and
  #   the ticker universe. All of it is derived from upstream APIs, so the file
  #   is disposable: delete it and the next run refills it.
  # - **`portfolio.db`** ({Portfolio}) holds portfolios, trades, positions, and
  #   valuation history. None of it can be re-fetched from anywhere.
  #
  # Keeping them apart means "clear the price cache" can never endanger a trade
  # record. The cost is that `trades.ticker` is a soft reference to
  # `stocks.ticker` rather than a foreign key, since SQLite does not enforce
  # foreign keys across attached databases.
  #
  # @example
  #   SQA::Store.market.prices("aapl")
  #   SQA::Store.portfolio.portfolios(kind: "watchlist")
  #
  module Store
    class << self
      # The market data store, opened lazily against the configured path.
      #
      # @return [SQA::Store::Market]
      def market = @market ||= Market.new(market_path)

      # The portfolio store, opened lazily against the configured path.
      #
      # @return [SQA::Store::Portfolio]
      def portfolio = @portfolio ||= Portfolio.new(portfolio_path)

      # @return [Pathname] Configured location of `sqa.db`
      def market_path = SQA.data_dir + SQA.config.database_filename

      # @return [Pathname] Configured location of `portfolio.db`
      def portfolio_path = SQA.data_dir + SQA.config.portfolio_database_filename

      # Closes both stores and drops the memoized handles, so the next call
      # reopens against whatever the configuration now says.
      #
      # @return [void]
      def reset!
        @market&.close
        @portfolio&.close
        @market = nil
        @portfolio = nil
      end
    end
  end
end
