# lib/sqa/store/base.rb
# frozen_string_literal: true

require 'date'
require 'sqlite3'
require 'time' # Time#iso8601

module SQA
  module Store
    # Shared connection handling and schema migration for SQA's SQLite stores.
    #
    # Subclasses supply an ordered list of DDL batches via {#migrations}. The
    # index of a batch plus one is the schema version it establishes, recorded
    # in SQLite's `user_version` pragma. Migrations are therefore append-only:
    # editing or reordering an already-released batch would leave existing
    # databases on a version whose schema no longer matches.
    #
    # @example
    #   store = SQA::Store::Market.new("~/sqa_data/sqa.db")
    #   store.schema_version  # => 1
    #
    class Base
      # @return [Pathname] Absolute path to the SQLite database file
      attr_reader :path

      # @return [SQLite3::Database] The open connection
      attr_reader :db

      # Opens (creating if necessary) the database and brings its schema up to
      # date.
      #
      # @param path [String, Pathname] Path to the SQLite file
      def initialize(path)
        @path = Pathname.new(path.to_s).expand_path
        @path.dirname.mkpath
        @db = SQLite3::Database.new(@path.to_s)

        configure_connection
        migrate!
      end

      # Ordered DDL batches, oldest first. Index + 1 is the resulting schema
      # version.
      #
      # @return [Array<String>]
      # @raise [NotImplementedError] Always, unless overridden
      def migrations
        raise NotImplementedError, "#{self.class} must implement #migrations"
      end

      # @return [Integer] The schema version currently recorded in the file
      def schema_version = db.get_first_value('PRAGMA user_version').to_i

      # @return [Boolean]
      def closed? = db.closed?

      # Closes the connection. Safe to call more than once.
      #
      # @return [void]
      def close
        db.close unless db.closed?
      end

      # Runs a block inside a transaction, joining an outer transaction rather
      # than nesting (SQLite has no nested transactions).
      #
      # @yield the work to perform atomically
      # @return [Object] the block's value
      def transaction(&)
        return yield if db.transaction_active?

        db.transaction(&)
      end

      # Normalizes a Date, Time, or parseable String to an ISO-8601 date string.
      #
      # @param value [Date, Time, String, nil]
      # @return [String, nil]
      def self.iso_date(value)
        case value
        when nil    then nil
        when Date   then value.iso8601
        when Time   then value.to_date.iso8601
        else             Date.parse(value.to_s).iso8601
        end
      end

      # @return [String] Current UTC timestamp, ISO-8601
      def self.now = Time.now.utc.iso8601

      private

      def configure_connection
        db.results_as_hash = true
        db.busy_timeout    = 5_000

        db.execute('PRAGMA journal_mode = WAL')
        db.execute('PRAGMA foreign_keys = ON')
        db.execute('PRAGMA synchronous  = NORMAL')
      end

      def migrate!
        migrations.each_with_index.drop(schema_version).each do |sql, index|
          db.transaction do
            db.execute_batch(sql)
            # PRAGMA does not accept bind parameters; index is a local Integer.
            db.execute("PRAGMA user_version = #{index + 1}")
          end
        end
      end
    end
  end
end
