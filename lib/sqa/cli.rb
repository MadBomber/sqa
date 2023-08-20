# lib/sqa/cli.rb

require 'tty-option'

require_relative '../sqa'


module SQA
	class CLI

    banner <<~BANNER

      Simple Qualitive Analysis (SQA)

      Usage:  sqa [options]

      OPTIONS:
    BANNER

    option :config_file,
      short:        "-c FILEPATH",
      long:         "--config FILEPATH",
      default:      "~/.sqa.rb",
      description:  "The filepath to the configuration to use"

    option :log_level,
      short:        "-l LEVEL",
      long:         "--log_level LEVEL",
      description:  "Set the log level (debug, info, warn, error, fatal)",
      required:     true,
      in:           [:debug, :info, :warn, :error, :fatal],
      proc:         Proc.new { |l| l.to_sym }

    option :portfolio,
      short:        "-p FIELNAME",
      long:         "--portfolio FIELNAME",
      default:      "portfolio.csv",
      description:  "Set the filename of the portfolio"

    option :trades,
      short:        "-t FIELNAME",
      long:         "--trades FIELNAME",
      default:      "trades.csv",
      description:  "Set the filename into which trades are stored"

    option :help,
      short:        "-h",
      long:         "--help",
      description:  "Show this message",
      on:           :tail,
      boolean:      true,
      show_options: true,
      exit:         0

      # verbose
      # debug
      # version



    def run(argv = ARGV)
      parse_options(argv)
      SQA::Config.merge!(config)
    end
	end
end
