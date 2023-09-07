# sqa/test/config_test.rb


require           'minitest/autorun'
require_relative  'test_helper'
require           'sqa/cli'

class ConfigTest < Minitest::Test
  def test_default_config
    SQA::Config.reset # reset config to defaults

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


  def test_config_file_override
    argv = "--config #{__dir__}/config_files/config_file_override.yml"
    SQA.init(argv)

    assert_equal "override_sqa_data",       SQA.config.data_dir
    assert_equal "override_portfolio.csv",  SQA.config.portfolio_filename
    assert_equal "override_trades.csv",     SQA.config.trades_filename
  end


  def test_cli_overrides_config_file
    argv = "--data-dir magic_xyzzy --config #{__dir__}/config_files/config_file_override.yml"
    SQA.init(argv)

    assert_equal "magic_xyzzy",       SQA.config.data_dir
  end



  def test_cli_override
    result = %x[ SQA_DATA_DIR=xyzzy ruby #{__dir__}/config_cli_override.rb ]
    assert_equal "magic", result
  end
end
