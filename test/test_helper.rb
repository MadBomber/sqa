# ./test/test_helper.rb

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'

  add_group 'Strategies', 'lib/sqa/strategy'
  add_group 'DataFrame', 'lib/sqa/data_frame'
  add_group 'Indicators', 'lib/sqa/indicator'
  add_group 'API', 'lib/api'
  add_group 'Core', 'lib/sqa'
end

require 'sqa'
require 'minitest/autorun'
require 'minitest/mock'
require 'tmpdir'
require 'fileutils'

# Isolate the entire suite from the developer's real data.
#
# SQA::Stock and SQA::Ticker default to SQA::Store.market, which resolves
# through SQA.config.data_dir -- and SQA_DATA_DIR commonly points at a real
# collection of stocks and portfolios. Without this, running the tests writes
# fixture tickers into that database. It has happened: rows for "!!!!" and
# "invalid_ticker_9999" reached a live sqa.db this way, the same way the
# pre-SQLite suite used to leave !!!!.json in the data directory.
#
# Tests that want a store should still construct their own against a tmpdir;
# this only guarantees that forgetting to do so is harmless.
SQA_TEST_DATA_DIR = Dir.mktmpdir('sqa-test-data')
SQA.config.data_dir = SQA_TEST_DATA_DIR
SQA::Store.reset!

# Directory trees a test is allowed to write into. Anything else means the
# sandbox was lost and a store would resolve against real data.
SQA_TEST_SANDBOX_ROOTS = [
  Dir.tmpdir,
  File.realpath(Dir.tmpdir),
  '/tmp', '/private/tmp', '/var/folders', '/private/var/folders'
].uniq.freeze

# Setting data_dir once is not enough: SQA::Config.reset discards the whole
# config object (config_test.rb exercises exactly that), which would silently
# hand the next test a data_dir pointing at real data. Minitest randomizes
# order, so whether that mattered was previously down to luck. This re-asserts
# the sandbox before every single test.
module SQA
  module TestIsolation
    def before_setup
      super
      return if SQA::TestIsolation.sandboxed?(SQA.config.data_dir)

      SQA.config.data_dir = SQA_TEST_DATA_DIR
      SQA::Store.reset! # drop any handle memoized against the escaped path
    end

    def self.sandboxed?(path)
      SQA_TEST_SANDBOX_ROOTS.any? { |root| path.to_s.start_with?(root) }
    end
  end
end

Minitest::Test.prepend(SQA::TestIsolation)

Minitest.after_run do
  SQA::Store.reset!
  FileUtils.remove_entry(SQA_TEST_DATA_DIR) if File.directory?(SQA_TEST_DATA_DIR)
end

require 'debug_me'
Object.include(DebugMe)

$data = Struct.new(
  :period,
  :high_prices,
  :low_prices,
  :close_prices,
  :volume,
  :expected_tr,
  :expected_atr,
  :expected_sma,
  :expected_ema
).new

$data.period        = 3
$data.high_prices   = [10.0, 12.0, 15.0, 14.0, 18.0, 21.0, 20.0]
$data.low_prices    = [8.0, 11.0, 13.0, 12.0, 16.0, 19.0, 18.0]
$data.close_prices  = [9.0, 11.0, 14.0, 13.0, 17.0, 20.0, 19.0]
$data.expected_tr   = [3.0,  4.0,  2.0,  5.0,  4.0,  2.0]
$data.expected_atr  = [3.0,  3.5,  3.0,  3.67, 3.67, 3.67]

$data.volume        = (0..9).to_a
$data.expected_sma  = [0.0, 0.5, 1.0,  2.0,  3.0,  4.0,  5.0,  6.0,  7.0, 8.0]
$data.expected_ema  = [0.0, 0.5, 1.25, 2.13, 3.06, 4.03, 5.02, 6.01, 7.0, 8.0]

$data.freeze
