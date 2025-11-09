# frozen_string_literal: true

require_relative 'test_helper'
require 'tempfile'

class ConfigTest < Minitest::Test
  def setup
    @config = SQA::Config.new
  end

  def teardown
    # Reset to default config after each test
    SQA::Config.reset
  end

  def test_default_data_dir
    assert_equal Nenv.home + "/sqa_data", @config.data_dir
  end

  def test_default_portfolio_filename
    assert_equal "portfolio.csv", @config.portfolio_filename
  end

  def test_default_trades_filename
    assert_equal "trades.csv", @config.trades_filename
  end

  def test_default_log_level
    assert_equal :info, @config.log_level
  end

  def test_default_debug_false
    assert_equal false, @config.debug
  end

  def test_default_verbose_false
    assert_equal false, @config.verbose
  end

  def test_default_plotting_library
    assert_equal :gruff, @config.plotting_library
  end

  def test_default_lazy_update
    assert_equal false, @config.lazy_update
  end

  def test_debug_predicate_method
    config = SQA::Config.new(debug: true)
    assert config.debug?

    config = SQA::Config.new(debug: false)
    refute config.debug?
  end

  def test_verbose_predicate_method
    config = SQA::Config.new(verbose: true)
    assert config.verbose?

    config = SQA::Config.new(verbose: false)
    refute config.verbose?
  end

  def test_debug_coercion_from_string_true
    config = SQA::Config.new(debug: "true")
    assert config.debug?

    config = SQA::Config.new(debug: "yes")
    assert config.debug?

    config = SQA::Config.new(debug: "1")
    assert config.debug?
  end

  def test_debug_coercion_from_string_false
    config = SQA::Config.new(debug: "false")
    refute config.debug?

    config = SQA::Config.new(debug: "no")
    refute config.debug?

    config = SQA::Config.new(debug: "0")
    refute config.debug?
  end

  def test_debug_coercion_from_numeric
    config = SQA::Config.new(debug: 1)
    assert config.debug?

    config = SQA::Config.new(debug: 0)
    refute config.debug?
  end

  def test_verbose_coercion_from_string
    config = SQA::Config.new(verbose: "true")
    assert config.verbose?

    config = SQA::Config.new(verbose: "false")
    refute config.verbose?
  end

  def test_log_level_coercion_to_symbol
    config = SQA::Config.new(log_level: "debug")
    assert_equal :debug, config.log_level
  end

  def test_log_level_values
    # Valid log levels
    [:debug, :info, :warn, :error, :fatal].each do |level|
      config = SQA::Config.new(log_level: level)
      assert_equal level, config.log_level
    end
  end

  def test_plotting_library_coercion_to_symbol
    config = SQA::Config.new(plotting_library: "gruff")
    assert_equal :gruff, config.plotting_library
  end

  def test_property_translation_portfolio
    config = SQA::Config.new(portfolio: "custom_portfolio.csv")
    assert_equal "custom_portfolio.csv", config.portfolio_filename
  end

  def test_property_translation_trades
    config = SQA::Config.new(trades: "custom_trades.csv")
    assert_equal "custom_trades.csv", config.trades_filename
  end

  def test_property_translation_plot_lib
    config = SQA::Config.new(plot_lib: :gruff)
    assert_equal :gruff, config.plotting_library
  end

  def test_property_translation_lazy
    config = SQA::Config.new(lazy: true)
    assert_equal true, config.lazy_update
  end

  def test_initialize_with_hash
    config = SQA::Config.new(data_dir: "/custom/path", debug: true)

    assert_equal "/custom/path", config.data_dir
    assert config.debug?
  end

  def test_config_file_property
    config = SQA::Config.new(config_file: "/path/to/config.yml")
    assert_equal "/path/to/config.yml", config.config_file
  end

  def test_dump_config_property
    config = SQA::Config.new(dump_config: "/path/to/dump.yml")
    assert_equal "/path/to/dump.yml", config.dump_config
  end

  def test_command_property
    config = SQA::Config.new(command: "analysis")
    assert_equal "analysis", config.command
  end

  def test_class_method_reset
    SQA.config.data_dir = "/custom"
    assert_equal "/custom", SQA.config.data_dir

    SQA::Config.reset

    assert_equal Nenv.home + "/sqa_data", SQA.config.data_dir
  end

  def test_responds_to_from_file
    assert_respond_to @config, :from_file
  end

  def test_responds_to_dump_file
    assert_respond_to @config, :dump_file
  end

  def test_responds_to_inject_additional_properties
    assert_respond_to @config, :inject_additional_properties
  end

  def test_yaml_config_file_loading
    skip "Config file loading requires write access to temp directory"

    Tempfile.create(['config', '.yml']) do |f|
      f.write({ data_dir: "/yaml/test/path", debug: true }.to_yaml)
      f.rewind

      config = SQA::Config.new(config_file: f.path)
      config.from_file

      assert_equal "/yaml/test/path", config.data_dir
      assert config.debug?
    end
  end

  def test_json_config_file_loading
    skip "Config file loading requires write access to temp directory"

    Tempfile.create(['config', '.json']) do |f|
      f.write({ data_dir: "/json/test/path", verbose: true }.to_json)
      f.rewind

      config = SQA::Config.new(config_file: f.path)
      config.from_file

      assert_equal "/json/test/path", config.data_dir
      assert config.verbose?
    end
  end

  def test_toml_config_file_loading
    skip "Config file loading requires write access to temp directory"

    Tempfile.create(['config', '.toml']) do |f|
      f.write(TomlRB.dump({ data_dir: "/toml/test/path", debug: true }))
      f.rewind

      config = SQA::Config.new(config_file: f.path)
      config.from_file

      assert_equal "/toml/test/path", config.data_dir
      assert config.debug?
    end
  end

  def test_invalid_config_file_raises_error
    config = SQA::Config.new(config_file: "/nonexistent/file.txt")

    assert_raises SQA::BadParameterError do
      config.from_file
    end
  end

  def test_dump_file_without_config_file_raises_error
    assert_raises SQA::BadParameterError do
      @config.dump_file
    end
  end

  def test_tilde_expansion_in_data_dir
    skip "Config file loading requires write access to temp directory"

    Tempfile.create(['config', '.yml']) do |f|
      f.write({ data_dir: "~/custom_data" }.to_yaml)
      f.rewind

      config = SQA::Config.new(config_file: f.path)
      config.from_file

      assert_equal Nenv.home + "/custom_data", config.data_dir
    end
  end
end
