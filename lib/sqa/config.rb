# lib/sqa/config.rb

# The hierarchies of values should be:
#   default
#   envar ..... overrides default
#   config file ..... overrides envar
#   command line parameters ...... overrides config file

# TODO: Replace this with a Hashie class
require 'tty-config'

module SQA
	class Config
    attr_reader :config

    def initialize
      @config              = TTY::Config.new
      @config.filename = "sqa"
      @config.extname = ".yml"
      @config.append_path Dir.pwd   # Look in the local directory first
      @config.append_path Dir.home  # Then the home directory

      set_defaults
      override_with_envars
    end


    def set_defaults
      @config.set( :config_file, value: "~/.sqa.rb" )
      @config.set( :data_dir   , value: HOME + "sqa_data" )
      @config.set( :debug      , value: false )
      @config.set( :lazy       , value: false )
      @config.set( :log_level  , value: :info )
      @config.set( :plot_lib   , value: :gruff ) # TODO: use svg-grap
      @config.set( :portfolio  , value: "portfolio.csv" )
      @config.set( :trades     , value: "trades.csv" )
      @config.set( :verbose    , value: false )
      # @config.set( :version    , value: SQA::Version.to_s )
    end


    # SMELL:  Does this load from the envar everytime there
    #         a fetch or just the first time?
    def override_with_envars(prefix = "SQA")
      config.env_prefix     = prefix.upcase
      config.env_separator  = "_" # Used for nesting config names
      config.autoload_env
    end

    # TODO: It is awkard to have to do this
    #       SQA::Config.config[:thing] to get the
    #       value of thing ...
    #       Consider replacing with Hashie::Dash
    def self.config
      @config ||= self.new.config
    end


    def self.run
      config
    end
	end
end
