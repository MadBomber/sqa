# lib/sqa/config.rb

# The hierarchies of values should be:
#   default
#   envar ..... overrids default
#   config file ..... overrides envar
#   command line parameters ...... overrides config file

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
      @config.set(:config_file) { "~/.sqa.rb" }
      @config.set(:data_dir   ) { HOME + "sqa_data" }
      @config.set(:debug      ) { false }
      @config.set(:lazy       ) { false }
      @config.set(:log_level  ) { :info }
      @config.set(:plot_lib   ) { :gruff} # TODO: use svg-graph
      @config.set(:portfolio  ) { "portfolio.csv" }
      @config.set(:trades     ) { "trades.csv" }
      @config.set(:verbose    ) { false }
      @config.set(:version    ) { SQA::Version.to_s }
    end


    # SMELL:  Does this load from the envar everytime there
    #         a fetch or just the first time?
    def override_with_envars(prefix = "SQA")
      config.env_prefix     = prefix.upcase
      config.env_separator  = "___" # Used for nesting config names
      config.autoload_env
    end


    def self.config
      @config ||= self.new.config
    end


    def self.run
      config
    end
	end
end
