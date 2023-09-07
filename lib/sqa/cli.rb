# lib/sqa/cli.rb

require 'tty-option'

require_relative '../sqa'

# SMELL:  Architectyre has become confused between CLI and Command

# TODO: Fix the mess between CLI and Command


module SQA
	class CLI
    include TTY::Option

    header "Stock Quantitative Analysis (SQA)"
    footer "WARNING: This is a toy, a play thing, not intended for serious use."

    program "sqa"
    desc    "A collection of things"

    example "sqa -c ~/.sqa.yml -p portfolio.csv -t trades.csv --data-dir ~/sqa_data"


    option :config_file do
      short "-c string"
      long  "--config string"
      desc  "Path to the config file"
    end

    option :log_level do
      short   "-l string"
      long    "--log_level string"
      # default SQA.config.log_level
      desc    "Set the log level (debug, info, warn, error, fatal)"
    end

    option :portfolio do
      short   "-p string"
      long    "--portfolio string"
      # default SQA.config.portfolio_filename
      desc    "Set the filename of the portfolio"
    end


    option :trades do
      short   "-t string"
      long    "--trades string"
      # default SQA.config.trades_filename
      desc    "Set the filename into which trades are stored"
    end


    option :data_dir do
      long    "--data-dir string"
      # default SQA.config.data_dir
      desc    "Set the directory for the SQA data"
    end

    flag :dump_config do
      long "--dump-config path_to_file"
      desc "Dump the current configuration"
    end

    flag :help do
      short "-h"
      long "--help"
      desc "Print usage"
    end

    flag :version do
      long "--version"
      desc "Print version"
    end

    flag :debug do
      short   "-d"
      long    "--debug"
      # default SQA.config.debug
      desc    "Turn on debugging output"
    end

    flag :verbose do
      short   "-v"
      long    "--verbose"
      # default SQA.config.debug
      desc    "Print verbosely"
    end

    class << self
      @@subclasses          = []
      @@commands_available  = []

      def names
        '['+ @@commands_available.join('|')+']'
      end

      def inherited(subclass)
        super
        @@subclasses          << subclass
        @@commands_available  << subclass.command.join
      end

      def command_descriptions
        help_block = "Optional Command Available:"

        @@commands_available.size.times do |x|
          klass = @@subclasses[x]
          help_block << "\n  " + @@commands_available[x] + " - "
          help_block << klass.desc.join
        end

        help_block
      end


      ##################################################
      def run(argv = ARGV)
        cli    = new
        parser = cli.parse(argv)
        params = parser.params

        if params[:help]
          print parser.help
          exit(0)

        elsif params.errors.any?
          puts params.errors.summary
          exit(1)

        elsif params[:version]
          puts SQA.version
          exit(0)

        elsif params[:dump_config]
          SQA.config.config_file  = params[:dump_config]
          `touch #{SQA.config.config_file}`
          SQA.config.dump_file
          exit(0)

        elsif params[:config_file]
          # Override the defaults <- envars <- config file content
          SQA.config.config_file = params[:config_file]
          SQA.config.from_file
        end

        # Override the defaults <- envars <- config file <- cli parameters
        SQA.config.merge!(remove_temps params.to_h)

        if SQA.debug? || SQA.verbose?
          debug_me("config after CLI parameters"){[
            "SQA.config"
          ]}
        end
      end

      def remove_temps(a_hash)
        temps = %i[ help version dump ]
        # debug_me{[ :a_hash ]}
        a_hash.reject{|k, _| temps.include? k}
      end
    end
	end
end

require_relative 'analysis'
require_relative 'web'

# First Load TTY-Option's command content with all available commands
# then these have access to the entire ObjectSpace ...
SQA::CLI.command SQA::CLI.names
SQA::CLI.example SQA::CLI.command_descriptions

