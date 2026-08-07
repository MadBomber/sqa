# lib/sqa/store/portfolio.rb
# frozen_string_literal: true

require 'date'
require 'json'
require_relative 'base'

module SQA
  module Store
    # Persistent store for portfolios, their trades, positions, and valuation
    # history. Backed by `portfolio.db`.
    #
    # Unlike {SQA::Store::Market}, nothing in here can be re-fetched from an
    # API — it is the user's own record. That asymmetry is the whole reason the
    # two databases are separate files: `sqa.db` can be deleted to force a
    # refresh without putting trade history at risk.
    #
    # Not to be confused with {SQA::Portfolio}, the in-memory portfolio object
    # that {SQA::Backtest} drives. This class persists that object; it does not
    # replace it. Backtests and genetic-programming runs create thousands of
    # throwaway portfolios and must never touch the disk, so persistence is
    # always an explicit call.
    #
    # @example Recording a live trade
    #   store = SQA::Store::Portfolio.new("~/sqa_data/portfolio.db")
    #   id = store.create_portfolio(name: "Roth IRA", kind: "real", initial_cash: 25_000.0)
    #   store.record_trade(portfolio_id: id, ticker: "aapl", action: "buy",
    #                      shares: 10, price: 150.0)
    #
    # @example Building a watchlist
    #   id = store.create_portfolio(name: "Dividend Watch", kind: "watchlist")
    #   store.watch(id, ticker: "ko", price: 62.50)
    #
    class Portfolio < Base
      # A portfolio is one of exactly three kinds:
      #
      # - `real`      — a live account with real money behind it
      # - `simulated` — not real, but takes simulated trades (e.g. developing
      #                 an automated strategy)
      # - `watchlist` — not real and never trades; a collection of stocks held
      #                 together to compare their performance against each other
      KINDS = %w[real simulated watchlist].freeze

      # `open` records a starting basis without moving cash. It is how a real
      # account imports positions it holds but has no trade record for, and how
      # a watchlist admits a member.
      ACTIONS = %w[buy sell open].freeze

      # Watchlist members are opened at equal notional value rather than an
      # equal share count, so a $500 stock and a $5 stock stay comparable and
      # the portfolio's total value reads as an equal-weight index of members.
      DEFAULT_WATCH_NOTIONAL = 1_000.0

      # Attributes {#update_portfolio} will write. Deliberately excludes cash
      # and initial_cash: those are consequences of the trade history, not
      # things to be edited directly.
      EDITABLE_ATTRIBUTES = %w[name kind description broker currency commission opened_on closed_on].freeze

      # Copy modes accepted by {#copy_portfolio}.
      COPY_MODES = %i[trades positions].freeze

      # A position as it is written — the shape the cost-basis arithmetic
      # produces and the `positions` table stores.
      Holding = Data.define(:ticker, :shares, :avg_cost, :total_cost, :opened_on) do
        # @param row [Hash, nil] A `positions` row
        # @return [Holding, nil] nil when nothing is held
        def self.from_row(row)
          return nil unless row

          new(ticker: row['ticker'], shares: row['shares'], avg_cost: row['avg_cost'],
              total_cost: row['total_cost'], opened_on: row['opened_on'])
        end
      end

      # The part of a trade that the position arithmetic depends on.
      Fill = Data.define(:ticker, :action, :shares, :price, :total, :date)

      class << self
        # Applies a buy or an open to a holding.
        #
        # Pure: no database, no instance state. A first purchase establishes
        # the basis; a subsequent one averages into it.
        #
        # @param fill [Fill]
        # @param held [Holding, nil] Existing holding, if any
        # @return [Holding] The resulting holding
        def increase(fill, held)
          unless held
            return Holding.new(ticker: fill.ticker, shares: fill.shares, avg_cost: fill.price,
                               total_cost: fill.total, opened_on: fill.date)
          end

          shares = held.shares + fill.shares
          cost   = held.total_cost + fill.total

          held.with(shares:, avg_cost: cost / shares, total_cost: cost)
        end

        # Applies a sale to a holding.
        #
        # Pure, as {.increase} is.
        #
        # @param fill [Fill]
        # @param held [Holding, nil]
        # @return [Holding, nil] nil when the sale closes the position entirely
        # @raise [SQA::BadParameterError] When nothing is held or too much is sold
        def decrease(fill, held)
          raise SQA::BadParameterError, "No position in #{fill.ticker}" unless held

          if fill.shares > held.shares
            raise SQA::BadParameterError,
                  "Insufficient shares: trying to sell #{fill.shares}, holding #{held.shares}"
          end

          return nil if fill.shares == held.shares

          # Average cost per share is unchanged by a partial sale; only the
          # remaining basis shrinks, proportionally.
          cost_per_share = held.total_cost / held.shares

          held.with(shares: held.shares - fill.shares,
                    total_cost: held.total_cost - (cost_per_share * fill.shares))
        end
      end

      # Ordered, append-only DDL batches. See {Base#migrations}.
      #
      # @return [Array<String>]
      def migrations
        [<<~SQL]
          CREATE TABLE portfolios (
            id           INTEGER PRIMARY KEY,
            name         TEXT    NOT NULL UNIQUE,
            kind         TEXT    NOT NULL CHECK (kind IN ('real', 'simulated', 'watchlist')),
            description  TEXT,
            broker       TEXT,
            currency     TEXT    NOT NULL DEFAULT 'USD',
            initial_cash REAL    NOT NULL DEFAULT 0.0,
            cash         REAL    NOT NULL DEFAULT 0.0,
            commission   REAL    NOT NULL DEFAULT 0.0,
            opened_on    TEXT    NOT NULL,
            closed_on    TEXT,
            created_at   TEXT    NOT NULL,
            updated_at   TEXT    NOT NULL
          );

          CREATE TABLE trades (
            id           INTEGER PRIMARY KEY,
            portfolio_id INTEGER NOT NULL REFERENCES portfolios(id) ON DELETE CASCADE,
            ticker       TEXT    NOT NULL,
            action       TEXT    NOT NULL CHECK (action IN ('buy', 'sell', 'open')),
            shares       REAL    NOT NULL CHECK (shares > 0),
            price        REAL    NOT NULL CHECK (price > 0),
            total        REAL    NOT NULL,
            commission   REAL    NOT NULL DEFAULT 0.0,
            traded_on    TEXT    NOT NULL,
            note         TEXT,
            created_at   TEXT    NOT NULL
          );

          CREATE INDEX idx_trades_portfolio_date ON trades (portfolio_id, traded_on);
          CREATE INDEX idx_trades_ticker         ON trades (portfolio_id, ticker);

          CREATE TABLE positions (
            portfolio_id INTEGER NOT NULL REFERENCES portfolios(id) ON DELETE CASCADE,
            ticker       TEXT    NOT NULL,
            shares       REAL    NOT NULL CHECK (shares > 0),
            avg_cost     REAL    NOT NULL,
            total_cost   REAL    NOT NULL,
            opened_on    TEXT,
            updated_at   TEXT    NOT NULL,
            PRIMARY KEY (portfolio_id, ticker)
          ) WITHOUT ROWID;

          CREATE TABLE valuations (
            portfolio_id    INTEGER NOT NULL REFERENCES portfolios(id) ON DELETE CASCADE,
            valued_on       TEXT    NOT NULL,
            cash            REAL    NOT NULL,
            positions_value REAL    NOT NULL,
            total_value     REAL    NOT NULL,
            PRIMARY KEY (portfolio_id, valued_on)
          ) WITHOUT ROWID;
        SQL
      end

      #############################################
      ## Portfolios

      # Creates a portfolio.
      #
      # @param name [String] Unique, human-facing name
      # @param kind [String] One of {KINDS}
      # @param initial_cash [Float] Starting cash; meaningless for a watchlist
      # @param commission [Float] Flat per-trade commission
      # @param description [String, nil]
      # @param broker [String, nil] Only meaningful when kind is `real`
      # @param currency [String]
      # @param opened_on [Date, String] Inception date
      # @return [Integer] The new portfolio's id
      # @raise [SQA::BadParameterError] If kind is not one of {KINDS}
      def create_portfolio(name:, kind:, initial_cash: 0.0, commission: 0.0,
                           description: nil, broker: nil, currency: 'USD',
                           opened_on: Date.today)
        validate_kind!(kind)

        cash   = kind == 'watchlist' ? 0.0 : initial_cash.to_f
        stamp  = Base.now
        values = [name, kind.to_s, description, broker, currency, cash, cash,
                  commission.to_f, Base.iso_date(opened_on), stamp, stamp]

        db.execute(<<~SQL, values)
          INSERT INTO portfolios (name, kind, description, broker, currency,
                                  initial_cash, cash, commission, opened_on,
                                  created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        SQL

        db.last_insert_row_id
      end

      # @param name [String]
      # @return [Hash, nil]
      def portfolio(name) = db.get_first_row('SELECT * FROM portfolios WHERE name = ?', [name])

      # @param id [Integer]
      # @return [Hash, nil]
      def portfolio_by_id(id) = db.get_first_row('SELECT * FROM portfolios WHERE id = ?', [id])

      # @param kind [String, nil] Restrict to one of {KINDS}
      # @return [Array<Hash>]
      def portfolios(kind: nil)
        return db.execute('SELECT * FROM portfolios ORDER BY name') if kind.nil?

        validate_kind!(kind)
        db.execute('SELECT * FROM portfolios WHERE kind = ? ORDER BY name', [kind.to_s])
      end

      # Deletes a portfolio and, by cascade, its trades, positions, and
      # valuations.
      #
      # @param id [Integer]
      # @return [Integer] Rows deleted
      def delete_portfolio(id)
        db.execute('DELETE FROM portfolios WHERE id = ?', [id])
        db.changes
      end

      #############################################
      ## Trades

      # Records a trade and applies it to the portfolio's cash and positions,
      # atomically.
      #
      # Trades are the source of truth; the `positions` table is a materialized
      # view maintained here and rebuildable via {#rebuild_positions!}.
      #
      # @param portfolio_id [Integer]
      # @param ticker [String]
      # @param action [String] One of {ACTIONS}
      # @param shares [Numeric] Must be positive; fractional shares allowed
      # @param price [Numeric] Must be positive
      # @param commission [Float, nil] Defaults to the portfolio's commission
      # @param traded_on [Date, String]
      # @param note [String, nil]
      # @return [Integer] The new trade's id
      # @raise [SQA::BadParameterError] On unknown action, non-positive
      #   quantities, a watchlist trade, or a sale exceeding the position
      def record_trade(portfolio_id:, ticker:, action:, shares:, price:,
                       commission: nil, traded_on: Date.today, note: nil)
        action = action.to_s
        symbol = normalize(ticker)

        validate_action!(action)
        raise SQA::BadParameterError, 'Shares must be positive' unless shares.to_f.positive?
        raise SQA::BadParameterError, 'Price must be positive'  unless price.to_f.positive?

        record = portfolio_by_id(portfolio_id) or
          raise SQA::BadParameterError, "No portfolio with id #{portfolio_id}"

        if record['kind'] == 'watchlist' && action != 'open'
          raise SQA::BadParameterError,
                "Watchlist '#{record['name']}' cannot #{action}; watchlists hold no positions to trade"
        end

        total = shares.to_f * price.to_f
        fee   = (commission || record['commission']).to_f
        date  = Base.iso_date(traded_on)

        transaction do
          db.execute(<<~SQL, [portfolio_id, symbol, action, shares.to_f, price.to_f, total, fee, date, note, Base.now])
            INSERT INTO trades (portfolio_id, ticker, action, shares, price,
                                total, commission, traded_on, note, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          SQL

          trade_id = db.last_insert_row_id

          apply_to_position(
            portfolio_id,
            Fill.new(ticker: symbol, action:, shares: shares.to_f, price: price.to_f, total:, date:)
          )
          apply_to_cash(portfolio_id, action, total, fee)

          trade_id
        end
      end

      # Adds a stock to a watchlist at equal notional value.
      #
      # @param portfolio_id [Integer]
      # @param ticker [String]
      # @param price [Numeric] Price on the day the stock was added
      # @param notional [Float] Dollar value to notionally allocate
      # @param on [Date, String]
      # @return [Integer] The new trade's id
      def watch(portfolio_id, ticker:, price:, notional: DEFAULT_WATCH_NOTIONAL, on: Date.today)
        record_trade(
          portfolio_id:,
          ticker:,
          action:    'open',
          shares:    notional.to_f / price,
          price:,
          traded_on: on
        )
      end

      # @param portfolio_id [Integer]
      # @param ticker [String, nil] Restrict to a single symbol
      # @return [Array<Hash>] Trades in chronological order
      def trades(portfolio_id, ticker: nil)
        return db.execute('SELECT * FROM trades WHERE portfolio_id = ? ORDER BY traded_on, id', [portfolio_id]) if ticker.nil?

        db.execute(
          'SELECT * FROM trades WHERE portfolio_id = ? AND ticker = ? ORDER BY traded_on, id',
          [portfolio_id, normalize(ticker)]
        )
      end

      #############################################
      ## Positions

      # @param portfolio_id [Integer]
      # @return [Array<Hash>]
      def positions(portfolio_id) = db.execute('SELECT * FROM positions WHERE portfolio_id = ? ORDER BY ticker', [portfolio_id])

      # @param portfolio_id [Integer]
      # @param ticker [String]
      # @return [Hash, nil]
      def position(portfolio_id, ticker)
        db.get_first_row('SELECT * FROM positions WHERE portfolio_id = ? AND ticker = ?', [portfolio_id, normalize(ticker)])
      end

      # Recomputes every position from the trade history, discarding the
      # materialized rows first.
      #
      # Use this to verify the `positions` table has not drifted from `trades`,
      # or after editing trades directly.
      #
      # @param portfolio_id [Integer]
      # @return [Integer] Number of open positions after the rebuild
      def rebuild_positions!(portfolio_id)
        transaction do
          db.execute('DELETE FROM positions WHERE portfolio_id = ?', [portfolio_id])

          trades(portfolio_id).each do |trade|
            apply_to_position(
              portfolio_id,
              Fill.new(
                ticker: trade['ticker'],
                action: trade['action'],
                shares: trade['shares'],
                price:  trade['price'],
                total:  trade['total'],
                date:   trade['traded_on']
              )
            )
          end
        end

        db.get_first_value('SELECT COUNT(*) FROM positions WHERE portfolio_id = ?', [portfolio_id]).to_i
      end

      #############################################
      ## Valuations

      # Records a portfolio's value on a date. Re-recording the same date
      # overwrites it, so a re-run of a valuation job is idempotent.
      #
      # @param portfolio_id [Integer]
      # @param cash [Float]
      # @param positions_value [Float]
      # @param valued_on [Date, String]
      # @return [Float] The total value written
      def record_valuation(portfolio_id:, cash:, positions_value:, valued_on: Date.today)
        total = cash.to_f + positions_value.to_f

        db.execute(<<~SQL, [portfolio_id, Base.iso_date(valued_on), cash.to_f, positions_value.to_f, total])
          INSERT INTO valuations (portfolio_id, valued_on, cash, positions_value, total_value)
          VALUES (?, ?, ?, ?, ?)
          ON CONFLICT(portfolio_id, valued_on) DO UPDATE SET
            cash            = excluded.cash,
            positions_value = excluded.positions_value,
            total_value     = excluded.total_value
        SQL

        total
      end

      # The equity curve, oldest first.
      #
      # @param portfolio_id [Integer]
      # @return [Array<Hash>]
      def valuations(portfolio_id) = db.execute('SELECT * FROM valuations WHERE portfolio_id = ? ORDER BY valued_on', [portfolio_id])

      #############################################
      ## Bridging to SQA::Portfolio

      # Persists an in-memory {SQA::Portfolio}.
      #
      # {SQA::Backtest} and {SQA::GeneticProgram} create thousands of throwaway
      # portfolios, so nothing is ever written implicitly — persistence only
      # happens through this call.
      #
      # @param portfolio [SQA::Portfolio] The object to persist
      # @param as [String] Name to store it under
      # @param kind [String] One of {KINDS}
      # @param replace [Boolean] Overwrite an existing portfolio of that name
      # @return [Integer] The portfolio's id
      # @raise [SQA::BadParameterError] On a name clash without `replace: true`
      def save_portfolio(portfolio, as:, kind: 'simulated', replace: false)
        validate_kind!(kind)
        existing = self.portfolio(as)

        if existing && !replace
          raise SQA::BadParameterError, "A portfolio named #{as.inspect} already exists; pass replace: true to overwrite"
        end

        transaction do
          delete_portfolio(existing['id']) if existing

          id = create_portfolio(name: as, kind:, initial_cash: portfolio.initial_cash,
                                commission: portfolio.commission)
          write_in_memory_state(id, portfolio)

          id
        end
      end

      # Rebuilds an in-memory {SQA::Portfolio} from stored state.
      #
      # Positions and cash are restored directly rather than by replaying
      # trades through {SQA::Portfolio#buy}, so a real account whose history
      # predates its recorded cash still loads faithfully.
      #
      # @param name [String]
      # @return [SQA::Portfolio]
      # @raise [SQA::BadParameterError] If no such portfolio exists
      def load_portfolio(name)
        record = portfolio(name) or raise SQA::BadParameterError, "No portfolio named #{name.inspect}"

        restored = SQA::Portfolio.new(initial_cash: record['initial_cash'], commission: record['commission'])
        restored.cash = record['cash']

        positions(record['id']).each { |row| restored.positions[row['ticker']] = to_position(row) }
        trades(record['id']).each    { |row| restored.trades << to_trade(row) }

        restored
      end

      #############################################
      ## Editing

      # Updates a portfolio's editable attributes.
      #
      # Cash and positions are never edited here — they are consequences of the
      # trade history. Change them by recording trades.
      #
      # @param id [Integer]
      # @param attrs [Hash] Any of :name, :kind, :description, :broker,
      #   :currency, :commission, :opened_on, :closed_on
      # @return [Hash] The updated portfolio row
      # @raise [SQA::BadParameterError] On an unknown attribute, an unknown
      #   kind, or a kind change the existing history cannot support
      def update_portfolio(id, **attrs)
        record = portfolio_by_id(id) or raise SQA::BadParameterError, "No portfolio with id #{id}"

        unknown = attrs.keys.map(&:to_s) - EDITABLE_ATTRIBUTES
        raise SQA::BadParameterError, "Cannot edit #{unknown.join(', ')}" unless unknown.empty?
        return record if attrs.empty?

        if attrs.key?(:kind)
          validate_kind!(attrs[:kind])
          validate_kind_change!(id, record, attrs[:kind].to_s)
        end

        values = attrs.map { |key, value| %i[opened_on closed_on].include?(key) ? Base.iso_date(value) : value }
        clause = attrs.keys.map { |key| "#{key} = ?" }.join(', ')

        db.execute("UPDATE portfolios SET #{clause}, updated_at = ? WHERE id = ?", values + [Base.now, id])

        portfolio_by_id(id)
      end

      #############################################
      ## Copying

      # Copies a portfolio, optionally into a different kind.
      #
      # Two copy modes, because they mean different things:
      #
      # - `:trades` replays the full trade history into the new portfolio, so
      #   cash and positions are re-derived exactly.
      # - `:positions` carries only the *current* holdings across, as `open`
      #   rows — the new portfolio holds the same stocks with the same cost
      #   basis but claims no trade history.
      #
      # The default depends on the target kind, and the defaults are the
      # cautious reading:
      #
      # - Copying **into `real`** defaults to `:positions`. Replaying simulated
      #   trades into a real portfolio would assert that trades happened with
      #   real money when they did not; `open` states the holding without
      #   fabricating its history. Pass `history: :trades` to override.
      # - Copying **into `watchlist`** is always `:positions` — a watchlist has
      #   no trades to hold, only members.
      # - Everything else defaults to `:trades`.
      #
      # @param id [Integer] Source portfolio
      # @param as [String] Name for the copy; must be unused
      # @param kind [String, nil] Target kind; defaults to the source's
      # @param history [Symbol, nil] `:trades` or `:positions`
      # @param initial_cash [Float, nil] Starting cash; defaults to the source's
      # @return [Integer] The new portfolio's id
      # @raise [SQA::BadParameterError] On unknown kind/mode or a duplicate name
      def copy_portfolio(id, as:, kind: nil, history: nil, initial_cash: nil)
        source = portfolio_by_id(id) or raise SQA::BadParameterError, "No portfolio with id #{id}"

        target_kind = (kind || source['kind']).to_s
        validate_kind!(target_kind)
        raise SQA::BadParameterError, "A portfolio named #{as.inspect} already exists" if portfolio(as)

        mode = resolve_copy_mode(target_kind, history)

        transaction do
          copy_id = create_portfolio(
            name:         as,
            kind:         target_kind,
            initial_cash: initial_cash || source['initial_cash'],
            commission:   source['commission'],
            description:  source['description'],
            broker:       target_kind == 'real' ? source['broker'] : nil,
            currency:     source['currency'],
            opened_on:    source['opened_on']
          )

          mode == :trades ? replay_trades(id, copy_id) : replay_positions(id, copy_id)

          copy_id
        end
      end

      #############################################
      ## Import / export / backup

      # Version stamped into exported documents. An import that does not carry
      # this key is rejected rather than silently misread — the failure mode
      # that made loose JSON files in a shared directory unsafe in the first
      # place.
      EXPORT_FORMAT = 'sqa.portfolio'
      EXPORT_VERSION = 1

      # Builds a self-contained document describing one portfolio.
      #
      # @param id [Integer]
      # @return [Hash] Portfolio, trades, positions, and valuations
      def export_portfolio(id)
        record = portfolio_by_id(id) or raise SQA::BadParameterError, "No portfolio with id #{id}"

        {
          'format'      => EXPORT_FORMAT,
          'version'     => EXPORT_VERSION,
          'exported_at' => Base.now,
          'portfolio'   => record.except('id'),
          'trades'      => trades(id).map { |row| row.except('id', 'portfolio_id') },
          'positions'   => positions(id).map { |row| row.except('portfolio_id') },
          'valuations'  => valuations(id).map { |row| row.except('portfolio_id') }
        }
      end

      # Writes {#export_portfolio} to a file as pretty JSON.
      #
      # @param id [Integer]
      # @param path [String, Pathname]
      # @return [Pathname] The file written
      def export_portfolio_to_file(id, path)
        target = Pathname.new(path.to_s).expand_path
        target.dirname.mkpath
        target.write(JSON.pretty_generate(export_portfolio(id)))

        target
      end

      # Writes a timestamped export into a directory.
      #
      # @param id [Integer]
      # @param dir [String, Pathname]
      # @param at [Time] Timestamp for the filename
      # @return [Pathname] The file written
      def backup_portfolio(id, dir, at: Time.now)
        record = portfolio_by_id(id) or raise SQA::BadParameterError, "No portfolio with id #{id}"
        slug   = record['name'].downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-|-\z/, '')

        export_portfolio_to_file(id, Pathname.new(dir.to_s) + "#{slug}-#{at.utc.strftime('%Y%m%dT%H%M%SZ')}.json")
      end

      # Imports a portfolio from a document or a file written by
      # {#export_portfolio_to_file}.
      #
      # The document's `format` and `version` keys are verified before anything
      # is read out of it, so pointing this at an unrelated JSON file fails
      # loudly instead of producing an empty portfolio.
      #
      # @param source [Hash, String, Pathname] Document or path to one
      # @param as [String, nil] Rename on import; required if the name is taken
      # @param kind [String, nil] Re-kind on import
      # @return [Integer] The new portfolio's id
      # @raise [SQA::BadParameterError] On a malformed document or name clash
      def import_portfolio(source, as: nil, kind: nil)
        document = source.is_a?(Hash) ? source : JSON.parse(Pathname.new(source.to_s).expand_path.read)
        validate_export!(document)

        record = document['portfolio']
        name   = as || record['name']
        target = (kind || record['kind']).to_s

        validate_kind!(target)
        raise SQA::BadParameterError, "A portfolio named #{name.inspect} already exists; pass as: to rename" if portfolio(name)

        transaction do
          id = create_portfolio(
            name:,
            kind:         target,
            initial_cash: record['initial_cash'],
            commission:   record['commission'],
            description:  record['description'],
            broker:       target == 'real' ? record['broker'] : nil,
            currency:     record['currency'] || 'USD',
            opened_on:    record['opened_on']
          )

          import_rows(id, document, target)

          id
        end
      end

      private

      def resolve_copy_mode(target_kind, history)
        if target_kind == 'watchlist'
          if history && history.to_sym == :trades
            raise SQA::BadParameterError,
                  'A watchlist holds no trades; copying into one is always history: :positions'
          end

          return :positions
        end

        return target_kind == 'real' ? :positions : :trades if history.nil?

        mode = history.to_sym
        return mode if COPY_MODES.include?(mode)

        raise SQA::BadParameterError, "Unknown copy mode #{history.inspect}; expected :trades or :positions"
      end

      def replay_trades(source_id, copy_id)
        trades(source_id).each do |trade|
          record_trade(
            portfolio_id: copy_id,
            ticker:       trade['ticker'],
            action:       trade['action'],
            shares:       trade['shares'],
            price:        trade['price'],
            commission:   trade['commission'],
            traded_on:    trade['traded_on'],
            note:         trade['note']
          )
        end
      end

      # Current holdings become `open` rows: same stock, same cost basis, no
      # claim about how the shares were acquired.
      def replay_positions(source_id, copy_id)
        positions(source_id).each do |held|
          record_trade(
            portfolio_id: copy_id,
            ticker:       held['ticker'],
            action:       'open',
            shares:       held['shares'],
            price:        held['avg_cost'],
            commission:   0.0,
            traded_on:    held['opened_on'] || Date.today,
            note:         "copied from portfolio #{source_id}"
          )
        end
      end

      # A watchlist has no trades, so a portfolio carrying buy/sell history
      # cannot become one in place without discarding that history. Copying is
      # the honest operation, so the error names it.
      def validate_kind_change!(id, record, new_kind)
        return if record['kind'] == new_kind || new_kind != 'watchlist'

        traded = db.get_first_value(
          "SELECT COUNT(*) FROM trades WHERE portfolio_id = ? AND action IN ('buy', 'sell')", [id]
        ).to_i
        return if traded.zero?

        raise SQA::BadParameterError,
              "Cannot convert #{record['name'].inspect} to a watchlist: it has #{traded} buy/sell trades. " \
              "Copy it instead: copy_portfolio(#{id}, as: ..., kind: 'watchlist')"
      end

      def validate_export!(document)
        unless document.is_a?(Hash) && document['format'] == EXPORT_FORMAT
          raise SQA::BadParameterError,
                "Not an SQA portfolio export: expected a #{EXPORT_FORMAT.inspect} format key"
        end

        version = document['version'].to_i
        unless version.between?(1, EXPORT_VERSION)
          raise SQA::BadParameterError,
                "Unsupported export version #{document['version'].inspect}; this build reads 1..#{EXPORT_VERSION}"
        end

        raise SQA::BadParameterError, "Export has no 'portfolio' section" unless document['portfolio'].is_a?(Hash)
        raise SQA::BadParameterError, "Export's portfolio has no name"    if document['portfolio']['name'].to_s.empty?
      end

      # Import is a faithful restore: trades are replayed verbatim. That is the
      # difference from {#copy_portfolio}, which derives a *new* portfolio and
      # therefore defaults to the cautious positions-only reading.
      def import_rows(id, document, target_kind)
        if target_kind == 'watchlist'
          Array(document['positions']).each do |held|
            record_trade(
              portfolio_id: id,
              ticker:       held['ticker'],
              action:       'open',
              shares:       held['shares'],
              price:        held['avg_cost'],
              traded_on:    held['opened_on'] || Date.today
            )
          end
        else
          Array(document['trades']).each do |trade|
            record_trade(
              portfolio_id: id,
              ticker:       trade['ticker'],
              action:       trade['action'],
              shares:       trade['shares'],
              price:        trade['price'],
              commission:   trade['commission'],
              traded_on:    trade['traded_on'],
              note:         trade['note']
            )
          end
        end

        Array(document['valuations']).each do |row|
          record_valuation(
            portfolio_id:    id,
            cash:            row['cash'],
            positions_value: row['positions_value'],
            valued_on:       row['valued_on']
          )
        end
      end

      def normalize(ticker) = ticker.to_s.strip.downcase

      # A portfolio loaded from the legacy portfolio.csv has positions but no
      # trades, because that file never carried any. Those holdings become
      # `open` rows; otherwise the trade history is authoritative and positions
      # re-derive from it.
      def write_in_memory_state(id, portfolio)
        if portfolio.trades.empty?
          portfolio.positions.each_value do |position|
            record_trade(portfolio_id: id, ticker: position.ticker, action: 'open',
                         shares: position.shares, price: position.avg_cost)
          end
        else
          portfolio.trades.each do |trade|
            record_trade(portfolio_id: id, ticker: trade.ticker, action: trade.action.to_s,
                         shares: trade.shares, price: trade.price,
                         commission: trade.commission, traded_on: trade.date)
          end
        end
      end

      def to_position(row)
        SQA::Portfolio::Position.new(row['ticker'], row['shares'], row['avg_cost'], row['total_cost'])
      end

      def to_trade(row)
        SQA::Portfolio::Trade.new(row['ticker'], row['action'].to_sym, row['shares'], row['price'],
                                  Date.parse(row['traded_on']), row['total'], row['commission'])
      end

      def validate_kind!(kind)
        return if KINDS.include?(kind.to_s)

        raise SQA::BadParameterError, "Unknown portfolio kind #{kind.inspect}; expected one of #{KINDS.join(', ')}"
      end

      def validate_action!(action)
        return if ACTIONS.include?(action)

        raise SQA::BadParameterError, "Unknown trade action #{action.inspect}; expected one of #{ACTIONS.join(', ')}"
      end

      # Mirrors SQA::Portfolio#buy / #sell cost-basis arithmetic so the stored
      # position matches what the in-memory object would have computed.
      #
      # The arithmetic lives in {.increase} and {.reduce}, which are pure
      # class methods over value objects — no database, independently testable,
      # and immune to the argument transposition that a six-positional writer
      # invites.
      def apply_to_position(portfolio_id, trade)
        held    = Holding.from_row(position(portfolio_id, trade.ticker))
        updated = trade.action == 'sell' ? self.class.decrease(trade, held) : self.class.increase(trade, held)

        updated.nil? ? drop_position(portfolio_id, trade.ticker) : write_position(portfolio_id, updated)
      end

      def drop_position(portfolio_id, ticker)
        db.execute('DELETE FROM positions WHERE portfolio_id = ? AND ticker = ?', [portfolio_id, ticker])
      end

      def write_position(portfolio_id, holding)
        values = [portfolio_id, holding.ticker, holding.shares, holding.avg_cost,
                  holding.total_cost, holding.opened_on, Base.now]

        db.execute(<<~SQL, values)
          INSERT INTO positions (portfolio_id, ticker, shares, avg_cost, total_cost, opened_on, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(portfolio_id, ticker) DO UPDATE SET
            shares     = excluded.shares,
            avg_cost   = excluded.avg_cost,
            total_cost = excluded.total_cost,
            updated_at = excluded.updated_at
        SQL
      end

      # `open` establishes a basis without a cash movement — it represents
      # shares already held, not shares bought.
      def apply_to_cash(portfolio_id, action, total, commission)
        delta = case action
                when 'buy'  then -(total + commission)
                when 'sell' then total - commission
                else             0.0
                end

        return if delta.zero?

        db.execute(
          'UPDATE portfolios SET cash = cash + ?, updated_at = ? WHERE id = ?',
          [delta, Base.now, portfolio_id]
        )
      end
    end
  end
end
