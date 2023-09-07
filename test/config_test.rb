# sqa/test/config_test.rb


require           'minitest/autorun'
require_relative  'test_helper'


class ConfigTest < Minitest::Test
  def test_default_config
  	SQA.init

  	expected = {
  		config_file:  			nil,
      dump_config:        nil,
  		data_dir: "/Users/dewayne/sqa_data",
  		debug: 							false,
  		lazy_update: 				false,
  		log_level: 					:info,
  		plotting_library: 	:gruff,
  		portfolio_filename: "portfolio.csv",
  		trades_filename: 		"trades.csv",
  		verbose: 						false,
  	}

  	assert SQA.config.is_a?(SQA::Config)
  	assert_equal expected, SQA.config.to_h
  end


  def test_envar_override
    result = %x[ SQA_DATA_DIR=xyzzy ruby #{__dir__}/config_envar_override.rb ]
    assert_equal "xyzzy", result
  end


  def test_cli_override
    result = %x[ SQA_DATA_DIR=xyzzy ruby #{__dir__}/config_cli_override.rb ]
    assert_equal "magic", result
  end
end
