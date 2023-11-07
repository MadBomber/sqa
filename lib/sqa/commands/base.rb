# .../sqa/cli/commands/base.rb

# SQA.config will be built with its defaults
# and envar over-rides BEFORE a command is
# process.  This means that options do not
# need to have a "default" value.

# Establish a Base command class that has global options
# available to all commands.

class Commands::Base < Dry::CLI::Command
  IGNORE_OPTIONS = %i[ version restart detach port ]

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
    required: false,
    type:     :boolean,
    # default:  false,
    desc:     'Print debug information',
    aliases:  %w[-d --debug]

  option :verbose,
    required: false,
    type:     :boolean,
    # default:  false,
    desc:     'Print verbose information',
    aliases:  %w[-v --verbose]


  option :version,
    required: false,
    type:     :boolean,
    default:  false,
    desc:     'Print version(s) and exit',
    aliases:  %w[--version]



  option :config_file,
    required: false,
    type:     :string,
    # default:  Nenv.sqa_config_filename || SQA.config.config_filename,
    desc:     "Path to the config file"


  option :log_level,
    required: false,
    type:     :string,
    # default:  Nenv.sqa_log_level || SQA.config.log_level,
    values:   %w[debug info warn error fatal ],
    desc:     "Set the log level"


  option :portfolio,
    required: false,
    aliases:  %w[ --portfolio --folio --file -f ],
    type:     :string,
    # default:  Nenv.sqa_portfollio_filename || SQA.config.portfolio_filename,
    desc:     "Set the filename of the portfolio"


  option :trades,
    required: false,
    aliases:  %w[ --trades ],
    type:     :string,
    # default:  Nenv.sqa_trades_filename || SQA.config.trades_filename,
    desc:     "Set the filename into which trades are stored"


  option :data_dir,
    required: false,
    aliases:  %w[ --data-dir --data --dir ],
    type:     :string,
    # default:  Nenv.sqa_data_dir || SQA.config.data_dir,
    desc:     "Set the directory for the SQA data"


  # TODO: This will have to be a command or maybe not
  #       maybe we can trap the parameters after the parse
  #       to update the SQA.config object.  At that time
  #       if the option :dump_
  option :dump_config,
    required: false,
    type:     :string,
    # default:  "",
    desc:     "Dump the current configuration to a file"


  # All command class call methods should start with
  # super so that this method is invoked.
  #
  # params is a Hash

  def call(params)
    debug_me(tag:"== Base call ==", levels: 4){[
      "params.class",
      :params
    ]}

    # show_errors(params.errors, exit_code: 1)  if params.errors.any?
    show_versions_and_exit                    if params[:version]

    SQA.config.from_config(:config_file)          if params.has_key?(:config_file)
    SQA.config.dump_config(params[:dump_config])  if params.has_key?(:dump_config)

    update_config(params)
  end

  ################################################
  private

  # errors is an Object from Dry::CLI
  # If exit_code is NOT nil, then this method
  # will not return.

  def show_errors(errors, exit_code: 1)
    STDERR.puts "\nThe following ERRORS were found:"
    STDERR.puts errors.summary
    STDERR.puts
    exit(exit_code) unless exist_code.nil?
  end


  def show_versions_and_exit
    self.class.ancestors.each do |ancestor|
      next unless ancestor.const_defined?(:VERSION)
      puts "#{ancestor}: #{ancestor::VERSION}"
    end

    puts "SQA: #{SQA::VERSION}" if SQA.const_defined?(:VERSION)

    exit(0)
  end

  def update_config(params)
    my_hash = params.reject { |key, _| IGNORE_OPTIONS.include?(key) }
    SQA.config.merge!(my_hash)
  end
end
