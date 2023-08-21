# lib/sqa/config.rb

# The hierarchies of values should be:
#   default
#   envar ..... overrides default
#   config file ..... overrides envar
#   command line parameters ...... overrides config file

require 'hashie'

module SQA
	class Config < Hashie::Dash
    include Hashie::Extensions::Dash::PropertyTranslation
    include Hashie::Extensions::Coercion
    include Hashie::Extensions::Dash::PredefinedValues

    property :config_file,  coerce: Pathname
    property :data_dir,     default: HOME + "sqa_data", coerce: Pathname

    # TODO: If no path is given, these files will be in
    #       data directory, otherwise, use the given path
    property :portfolio_filename, from: :portfolio, default: "portfolio.csv"
    property :trades_filename,    from: :trades,    default: "trades.csv"

    property :log_level,    default: :info,  coerce: Symbol, values: %i[debug info warn error fatal]

    # TODO: need a custom proc since there is no Boolean class in Ruby
    property :debug,        default: false  #, coerce: Boolean
    property :verbose,      default: false  #, coerce: Boolean

    # NOTE: Just here because it is a CLI option
    property :help
    property :version


    # TODO: use svg-grap
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
    private
    def override_with_envars(prefix = "SQA_")
      keys.each do |key|
        envar = ENV["#{prefix}#{key.to_s.upcase}"]
        send("#{key}=", envar) unless envar.nil?
      end
    end
	end
end

SQA.config = SQA::Config.new
