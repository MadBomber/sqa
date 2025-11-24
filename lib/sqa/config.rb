# lib/sqa/config.rb

# Configuration management for SQA with hierarchical value resolution.
# Values are resolved in this order (later overrides earlier):
#   1. default values
#   2. environment variables (SQA_ prefix)
#   3. config file (YAML, TOML, or JSON)
#   4. command line parameters
#
# @example Basic configuration
#   SQA.init
#   SQA.config.data_dir = "~/my_data"
#   SQA.config.debug = true
#
# @example Using config file
#   SQA.config.config_file = "~/.sqa.yml"
#   SQA.config.from_file
#
# @example Environment variables
#   # Set SQA_DATA_DIR, SQA_DEBUG, etc. before requiring sqa
#

require 'fileutils'
require 'yaml'
require 'toml-rb'

module SQA
  # Configuration class for SQA settings.
  # Extends Hashie::Dash for property-based configuration with coercion.
  #
  # @!attribute [rw] command
  #   @return [String, nil] Current command (nil, 'analysis', or 'web')
  # @!attribute [rw] config_file
  #   @return [String, nil] Path to configuration file
  # @!attribute [rw] dump_config
  #   @return [String, nil] Path to dump current configuration
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
	class Config < Hashie::Dash
    include Hashie::Extensions::Dash::PropertyTranslation
    include Hashie::Extensions::MethodAccess
    include Hashie::Extensions::Coercion

    # NOTE: PredefinedValues extension disabled due to compatibility issues.
    # Log level validation is handled via the `values:` option on the property instead.
    # include Hashie::Extensions::Dash::PredefinedValues

    property :command       # a String currently, nil, analysis or web
    property :config_file   # a String filepath for the current config overriden by cli options
    property :dump_config   # a String filepath into which to dump the current config

    property :data_dir,     default: Nenv.home + "/sqa_data"

    # Relative filenames are resolved against data_dir; absolute paths used as-is
    property :portfolio_filename, from: :portfolio, default: "portfolio.csv"
    property :trades_filename,    from: :trades,    default: "trades.csv"

    property :log_level,    default: :info,  coerce: Symbol, values: %i[debug info warn error fatal]

    # Boolean coercion handled via coerce_key blocks below (no Boolean class in Ruby)
    property :debug,        default: false
    property :verbose,      default: false

    # Plotting library - gruff is default; svggraph support could be added in future
    property :plotting_library, from: :plot_lib,  default: :gruff, coerce: Symbol
    property :lazy_update,      from: :lazy,      default: false


    coerce_key :debug, ->(v) do
      case v
      when String
        !!(v =~ /\A(true|t|yes|y|1)\z/i)
      when Numeric
        !v.to_i.zero?
      else
        v == true
      end
    end

    coerce_key :verbose, ->(v) do
      case v
      when String
        !!(v =~ /\A(true|t|yes|y|1)\z/i)
      when Numeric
        !v.to_i.zero?
      else
        v == true
      end
    end

    coerce_key :log_level, ->(v) do
      v.is_a?(String) ? v.to_sym : v
    end

    coerce_key :plotting_library, ->(v) do
      v.is_a?(String) ? v.to_sym : v
    end

    ########################################################

    # Creates a new Config instance with optional initial values.
    # Automatically applies environment variable overrides.
    #
    # @param a_hash [Hash] Initial configuration values
    def initialize(a_hash={})
      super(a_hash)
      override_with_envars
    end

    # Returns whether debug mode is enabled.
    # @return [Boolean] true if debug mode is on
    def debug?    = debug

    # Returns whether verbose mode is enabled.
    # @return [Boolean] true if verbose mode is on
    def verbose?  = verbose


    ########################################################

    # Loads configuration from a file.
    # Supports YAML (.yml, .yaml), TOML (.toml), and JSON (.json) formats.
    #
    # @return [void]
    # @raise [BadParameterError] If config file is invalid or unsupported format
    def from_file
      return if config_file.nil?

      if  File.exist?(config_file)    &&
          File.file?(config_file)     &&
          File.readable?(config_file)
        type = File.extname(config_file).downcase
      else
        type = "invalid"
      end

      # Config file format detection (YAML is most common)
      if ".json" == type
        incoming = form_json

      elsif %w[.yml .yaml].include?(type)
        incoming = from_yaml

      elsif ".toml" == type
        incoming = from_toml

      else
        raise BadParameterError, "Invalid Config File: #{config_file}"
      end

      if incoming.key?(:data_dir)
        incoming[:data_dir] = incoming[:data_dir].gsub(/^~/, Nenv.home)
      end

      merge! incoming
    end

    # Writes current configuration to a file.
    # Format is determined by file extension.
    #
    # @return [void]
    # @raise [BadParameterError] If config file is not set or unsupported format
    def dump_file
      if config_file.nil?
        raise BadParameterError, "No config file given"
      end

      FileUtils.touch(config_file)
      # unless  File.exist?(config_file)

      type = File.extname(config_file).downcase

      if ".json" == type
        dump_json

      elsif %w[.yml .yaml].include?(type)
        dump_yaml

      elsif ".toml" == type
        dump_toml

      else
        raise BadParameterError, "Invalid Config File Type: #{config_file}"
      end
    end

    # Injects additional properties from plugins.
    # Allows external code to register new configuration options.
    #
    # @return [void]
    def inject_additional_properties
      SQA::PluginManager.registered_properties.each do |prop, options|
        self.class.property(prop, options)
      end
    end


    ########################################################
    private

    def override_with_envars(prefix = "SQA_")
      keys.each do |key|
        envar = ENV["#{prefix}#{key.to_s.upcase}"]
        send("#{key}=", envar) unless envar.nil?
      end
    end


    #####################################
    ## override values from a config file

    def from_json
      ::JSON.load(File.open(config_file).read).symbolize_keys
    end

    def from_toml
      TomlRB.load_file(config_file).symbolize_keys
    end

    def from_yaml
      ::YAML.load_file(config_file).symbolize_keys
    end


    #####################################
    ## dump values to a config file

    def as_hash   = to_h.reject{|k, _| :config_file == k}
    def dump_json = File.open(config_file, "w") { |f| f.write JSON.pretty_generate(as_hash)}
    def dump_toml = File.open(config_file, "w") { |f| f.write TomlRB.dump(as_hash)}
    def dump_yaml = File.open(config_file, "w") { |f| f.write as_hash.to_yaml}


    #####################################
    class << self
      # Resets the configuration to default values.
      # Creates a new Config instance and assigns it to SQA.config.
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

# Auto-initialization with deprecation warning
# This will be removed in v1.0.0 - applications should call SQA.init explicitly
unless SQA::Config.initialized?
  warn "[SQA DEPRECATION] Auto-initialization at require time will be removed in v1.0. " \
       "Please call SQA.init explicitly in your application startup." if $VERBOSE
  SQA::Config.reset
end
