# lib/sqa/config.rb

# The hierarchies of values should be:
#   default
#   envar ..... overrides default
#   config file ..... overrides envar
#   command line parameters ...... overrides config file

require 'hashie'
require 'yaml'
require 'json'
require 'toml-rb'


module SQA
	class Config < Hashie::Dash
    include Hashie::Extensions::Dash::PropertyTranslation
    include Hashie::Extensions::Coercion
    include Hashie::Extensions::Dash::PredefinedValues

    property :config_file   #,  default: Nenv.home + "/.sqa.yml"
    property :data_dir,     default: Nenv.home + "/sqa_data"

    # TODO: If no path is given, these files will be in
    #       data directory, otherwise, use the given path
    property :portfolio_filename, from: :portfolio, default: "portfolio.csv"
    property :trades_filename,    from: :trades,    default: "trades.csv"

    property :log_level,    default: :info,  coerce: Symbol, values: %i[debug info warn error fatal]

    # TODO: need a custom proc since there is no Boolean class in Ruby
    property :debug,        default: false  #, coerce: Boolean
    property :verbose,      default: false  #, coerce: Boolean

    # TODO: use svggraph
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

    ########################################################
    def initialize(a_hash={})
      super(a_hash)
      override_with_envars
    end

    def debug?    = debug
    def verbose?  = verbose


    ########################################################
    def from_file
      return if config_file.nil?

      if  File.exist?(config_file)    &&
          File.file?(config_file)     &&
          File.readable?(config_file)
        type = File.extname(config_file).downcase
      else
        type = "invalid"
      end

      # TODO: arrange order in mostly often used

      if ".json" == type
        form_json

      elsif %w[.yml .yaml].include?(type)
        from_yaml

      elsif ".toml" == type
        from_toml

      else
        raise BadParameterError, "Invalid Config File: #{config_file}"
      end
    end

    def dump_file
      if config_file.nil?
        raise BadParameterError, "No config file given"
      end

      if  File.exist?(config_file)    &&
          File.file?(config_file)     &&
          File.writable?(config_file)
        type = File.extname(config_file).downcase
      else
        type = "invalid"
      end

      # TODO: arrange order in mostly often used

      if ".json" == type
        dump_json

      elsif %w[.yml .yaml].include?(type)
        dump_yaml

      elsif ".toml" == type
        dump_toml

      else
        raise BadParameterError, "Invalid Config File: #{config_file}"
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
      incoming  = ::JSON.load(File.open(config_file).read)
      debug_me{[ :incoming ]}
    end

    def from_toml
      incoming  = TomlRB.load_file(config_file)
      debug_me{[ :incoming ]}
    end

    def from_yaml
      incoming = ::YAML.load_file(config_file)
      debug_me{[ :incoming ]}
      merge! incoming
    end


    #####################################
    ## dump values to a config file

    def dump_json
      File.open(config_file, "w") { |f| f.write to_json}
    end

    def dump_toml
      File.open(config_file, "w") { |f| f.write TomlRB.dump(to_hash)}
    end

    def dump_yaml
      File.open(config_file, "w") { |f| f.write to_yaml}
    end
	end
end

SQA.config = SQA::Config.new
