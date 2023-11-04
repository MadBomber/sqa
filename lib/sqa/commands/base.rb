# .../sqa/cli/commands/base.rb

# Establish a Base command class that has global options
# available to all commands.

class Commands::Base < Dry::CLI::Command
  global_header <<~EOS

    SQA - Stock Quantitative Analysis
    by: MadBomber

    This is a work in progress.  It is not fit for anything
    other than play time.  ** Do not ** use it to make any
    kind of serious trading decisions.

  EOS

  global_footer <<~EOS

    SARNING: This product is a work in progress.  DO NOT USE
    for serious trading decisions.

    Copyright (c) 2023 - MadBomber Software

  EOS

  option :debug,
    type:     :boolean,
    default:  false,
    desc:     'Print debug information',
    aliases:  %w[-d --debug]

  option :verbose,
    type:     :boolean,
    default:  false,
    desc:     'Print verbose information',
    aliases:  %w[-v --verbose]


  option :config_file,
    type:     :string,
    default:  Nenv.sqa_config_filename || SQA.config.config_filename,
    desc:     "Path to the config file"


  option :log_level,
    type:     :string,
    default:  Nenv.sqa_log_level || SQA.config.log_level,
    values:   %w[debug info warn error fatal ],
    desc:     "Set the log level"


  option :portfolio,
    aliases:  %w[ --portfolio --folio --file -f ],
    type:     :string,
    default:  Nenv.sqa_portfollio_filename || SQA.config.portfolio_filename,
    desc:     "Set the filename of the portfolio"


  option :trades,
    aliases:  %w[ --trades ],
    type:     :string,
    default:  Nenv.sqa_trades_filename || SQA.config.trades_filename,
    desc:     "Set the filename into which trades are stored"


  option :data_dir,
    aliases:  %w[ --data-dir --data --dir ],
    type:     :string,
    default:  Nenv.sqa_data_dir || SQA.config.data_dir,
    desc:     "Set the directory for the SQA data"


  # TODO: This will have to be a command or maybe not
  #       maybe we can trap the parameters after the parse
  #       to update the SQA.config object.  At that time
  #       if the option :dump_
  option :dump_config,
    type:     :string,
    default:  "",
    desc:     "Dump the current configuration to a file"

end


__EBD__


