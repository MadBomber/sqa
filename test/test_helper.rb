# ./test/test_helper.rb

require 'sqa'

require 'debug_me'
include DebugMe

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
$data.low_prices    = [ 8.0, 11.0, 13.0, 12.0, 16.0, 19.0, 18.0]
$data.close_prices  = [ 9.0, 11.0, 14.0, 13.0, 17.0, 20.0, 19.0]
$data.expected_tr   = [       3.0,  4.0,  2.0,  5.0,  4.0,  2.0]
$data.expected_atr  = [       3.0,  3.5,  3.0,  3.67, 3.67, 3.67]

$data.volume        = (0..9).to_a
$data.expected_sma  = [0.0, 0.5, 1.0,  2.0,  3.0,  4.0,  5.0,  6.0,  7.0, 8.0]
$data.expected_ema  = [0.0, 0.5, 1.25, 2.13, 3.06, 4.03, 5.02, 6.01, 7.0, 8.0]

$data.freeze
