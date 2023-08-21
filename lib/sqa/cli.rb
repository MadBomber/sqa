# lib/sqa/cli.rb

require 'tty-option'

require_relative '../sqa'


module SQA
	class CLI
    include TTY::Option

    usage do
      program "sqa"

      desc "Simple Qualitative Analysis (SQA)"

      example "sqa -c ~/.sqa.yml -p portfolio.csv -t trades.csv --data-dir ~/sqa_data"
    end


    option :cpmfog_file do
      short "-c"
      long "--config string"
      desc "Path to the config file"
    end

    # option :log_level do
    #   short "-l LEVEL"
    #   long  "--log_level LEVEL"
    #   desc  "Set the log level (debug, info, warn, error, fatal)",
    # end


    option :portfolio do
      short   "-p string"
      long    "--portfolio string"
      default "portfolio.csv" # TODO: get from Config
      desc    "Set the filename of the portfolio"
    end


    option :trades do
      short   "-t string"
      long    "--trades string"
      default "trades.csv" # TODO: Get from Config
      desc    "Set the filename into which trades are stored"
    end


    option :data-dir do
      long    "--data-dir string"
      default "~/Documents/sqa_data" # TODO: Get from Config
      desc    "Set the directory for the SQA data"
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
      short "-d"
      long "--debug"
      desc "Turn on debugging output"
    end

    flag :verbose do
      short "-v"
      long "--verbose"
      desc "Print verbosely"
    end

    def self.run(argv = ARGV)
      cli    = new
      params = cli.parse(argv)

      if params[:help]
        print cli.help
        exit(0)

      elsif params.errors.any?
        puts params.errors.summary
        exit(1)

      elsif params[:config_file]
        SQA::Config.from_file params[:config_file]

      elsif params[:version]
        puts SQA.version
        exit(0)

      else
        ap params.to_h
      end

      # Override the defaults <- envars <- config file <- cli parameters
      SQA::Config.config.merge(params.to_h)
    end
	end
end
