# lib/sqa/config.rb

# Configuration management for SQA, built on myway_config (which extends
# anyway_config with XDG config-file loading and bundled defaults).
#
# Values are resolved in this order (later overrides earlier):
#   1. Bundled defaults      (lib/sqa/config/defaults.yml)
#   2. XDG user config       (~/.config/sqa/sqa.yml)
#   3. Project config        (./config/sqa.yml)
#   4. Environment variables (SQA_ prefix, e.g. SQA_DATA_DIR)
#   5. Programmatic values   (SQA::Config.new(...), CLI parameters)
#
# @example Basic configuration
#   SQA.init
#   SQA.config.data_dir = "~/my_data"
#   SQA.config.debug = true
#
# @example Loading an explicit config file
#   SQA.config.config_file = "~/.sqa.yml"
#   SQA.config.from_file
#
# @example Environment variables
#   # Set SQA_DATA_DIR, SQA_DEBUG, etc. before requiring sqa
#

require 'fileutils'
require 'yaml'
require 'json'
require 'toml-rb'
require 'myway_config'

# Register myway_config's XDG and bundled-defaults loaders with anyway_config.
MywayConfig.setup!

module SQA
  # Configuration class for SQA settings.
  #
  # Subclasses {MywayConfig::Base} so that configuration is sourced from the
  # bundled defaults, XDG user config, project config, and environment
  # variables automatically, while retaining the historical SQA public API
  # (property translations, boolean coercion, file load/dump).
  #
  # @!attribute [rw] command
  #   @return [String, nil] Current command (nil, 'analysis', or 'web')
  # @!attribute [rw] config_file
  #   @return [String, nil] Path to an explicit configuration file
  # @!attribute [rw] dump_config
  #   @return [String, nil] Path to dump the current configuration
  # @!attribute [rw] data_dir
  #   @return [String] Directory for data storage (default: ~/sqa_data)
  # @!attribute [rw] portfolio_filename
  #   @return [String] Portfolio CSV filename (default: portfolio.csv)
  # @!attribute [rw] trades_filename
  #   @return [String] Trades CSV filename (default: trades.csv)
  # @!attribute [rw] log_level
  #   @return [Symbol] Log level (:debug, :info, :warn, :error, :fatal)
  # @!attribute [rw] debug
  #   @return [Boolean] Enable debug mode
  # @!attribute [rw] verbose
  #   @return [Boolean] Enable verbose output
  # @!attribute [rw] plotting_library
  #   @return [Symbol] Plotting library to use (:gruff)
  # @!attribute [rw] lazy_update
  #   @return [Boolean] Skip API updates if cached data exists
  #
  class Config < MywayConfig::Base
    config_name :sqa
    env_prefix  :sqa
    defaults_path File.expand_path('config/defaults.yml', __dir__)

    # Attributes. Defaults for these come from the bundled defaults loader
    # (config/defaults.yml); declaring them here only defines the accessors.
    attr_config :command,
                :config_file,
                :dump_config,
                :data_dir,
                :portfolio_filename,
                :trades_filename,
                :log_level,
                :debug,
                :verbose,
                :plotting_library,
                :lazy_update

    # Legacy/short config keys accepted for backward compatibility, mapped to
    # their canonical attribute names. Applies to both Hash construction and
    # values read from a config file via {#from_file}.
    LEGACY_KEYS = {
      portfolio: :portfolio_filename,
      trades:    :trades_filename,
      plot_lib:  :plotting_library,
      lazy:      :lazy_update
    }.freeze

    # Coerces "truthy" strings/numbers to real booleans (env vars and file
    # values arrive as strings). Mirrors the historical SQA coercion rules.
    BOOLEAN_COERCION = lambda do |value|
      case value
      when String  then !(value =~ /\A(true|t|yes|y|1)\z/i).nil?
      when Numeric then !value.to_i.zero?
      else value == true
      end
    end

    # Coerces strings to symbols, leaving symbols (and nil) untouched.
    SYMBOL_COERCION = ->(value) { value.is_a?(String) ? value.to_sym : value }

    # Expands a leading ~ to the user's home directory.
    HOME_COERCION = ->(value) { value.is_a?(String) ? value.gsub(/^~/, Nenv.home) : value }

    coerce_types(
      debug:            BOOLEAN_COERCION,
      verbose:          BOOLEAN_COERCION,
      log_level:        SYMBOL_COERCION,
      plotting_library: SYMBOL_COERCION,
      data_dir:         HOME_COERCION
    )

    ########################################################

    # Creates a new Config instance.
    #
    # @param source [nil, String, Pathname, Hash] configuration source
    #   - nil: bundled defaults + XDG/project/env overrides
    #   - String/Pathname: path to a YAML config file
    #   - Hash: programmatic overrides (legacy keys are translated)
    def initialize(source = nil)
      source = translate_keys(source) if source.is_a?(Hash)
      super
    end

    # Returns whether debug mode is enabled.
    # @return [Boolean] true if debug mode is on
    def debug?    = !!debug

    # Returns whether verbose mode is enabled.
    # @return [Boolean] true if verbose mode is on
    def verbose?  = !!verbose

    ########################################################

    # Loads configuration from the file named by {#config_file}.
    # Supports YAML (.yml, .yaml), TOML (.toml), and JSON (.json).
    #
    # @return [void]
    # @raise [BadParameterError] If the config file is missing or unsupported
    def from_file
      return if config_file.nil?

      incoming =
        case readable_extension
        when '.json'         then from_json
        when '.yml', '.yaml' then from_yaml
        when '.toml'         then from_toml
        else raise BadParameterError, "Invalid Config File: #{config_file}"
        end

      apply_incoming(incoming)
    end

    # Writes the current configuration to the file named by {#config_file}.
    # Format is determined by the file extension.
    #
    # @return [void]
    # @raise [BadParameterError] If no config file is set or the type is unsupported
    def dump_file
      raise BadParameterError, "No config file given" if config_file.nil?

      FileUtils.touch(config_file)

      case File.extname(config_file).downcase
      when '.json'         then File.write(config_file, JSON.pretty_generate(as_hash))
      when '.yml', '.yaml' then File.write(config_file, as_hash.to_yaml)
      when '.toml'         then File.write(config_file, TomlRB.dump(as_hash))
      else raise BadParameterError, "Invalid Config File Type: #{config_file}"
      end
    end

    # Injects additional properties registered by plugins.
    #
    # @return [void]
    def inject_additional_properties
      return unless defined?(SQA::PluginManager)

      SQA::PluginManager.registered_properties.each_key do |prop|
        self.class.attr_config(prop) unless respond_to?(prop)
      end
    end

    ########################################################
    private

    # Translates legacy/short keys to canonical attribute names.
    #
    # @param hash [Hash] incoming key/value pairs
    # @return [Hash] hash with canonical, symbolized keys
    def translate_keys(hash)
      hash.each_with_object({}) do |(key, value), translated|
        sym = key.to_sym
        translated[LEGACY_KEYS.fetch(sym, sym)] = value
      end
    end

    # Applies a hash read from a config file to this instance, translating
    # legacy keys and expanding a leading ~ in data_dir.
    #
    # @param incoming [Hash] values loaded from the config file
    # @return [void]
    def apply_incoming(incoming)
      incoming = translate_keys(incoming)
      incoming[:data_dir] = HOME_COERCION.call(incoming[:data_dir]) if incoming.key?(:data_dir)

      incoming.each do |key, value|
        writer = "#{key}="
        public_send(writer, value) if respond_to?(writer)
      end
    end

    # @return [String] the downcased extension if config_file is readable, else "invalid"
    def readable_extension
      readable = File.exist?(config_file) && File.file?(config_file) && File.readable?(config_file)
      readable ? File.extname(config_file).downcase : 'invalid'
    end

    def from_json = ::JSON.parse(File.read(config_file)).transform_keys(&:to_sym)
    def from_toml = TomlRB.load_file(config_file).transform_keys(&:to_sym)
    def from_yaml = ::YAML.load_file(config_file).transform_keys(&:to_sym)

    # @return [Hash] current values suitable for dumping (config_file excluded)
    def as_hash = to_h.reject { |key, _| key.to_sym == :config_file }

    #####################################
    class << self
      # Resets the configuration to freshly-loaded values and assigns it to
      # SQA.config.
      #
      # @return [SQA::Config] The new config instance
      def reset
        @initialized = true
        SQA.config = new
      end

      # Returns whether the configuration has been initialized.
      #
      # @return [Boolean] true if reset has been called
      def initialized?
        @initialized ||= false
      end
    end
  end
end

# Auto-initialization with deprecation warning.
# This will be removed in v1.0.0 - applications should call SQA.init explicitly.
unless SQA::Config.initialized?
  if $VERBOSE
    warn "[SQA DEPRECATION] Auto-initialization at require time will be removed in v1.0. " \
         "Please call SQA.init explicitly in your application startup."
  end
  SQA::Config.reset
end
