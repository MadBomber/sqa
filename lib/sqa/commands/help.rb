# .../sqa/cli/commands/help.rb

# SMELL: Dry::CLI does _NOT_ implement help as a command
# so it can not be over-ridden nor callbacks
# attached to it.
#
# See: experiments/cli_options/dry-cli/*
#

# Override the default dry-cli help command
# SMELL: Dry::CLI can not be over-ridden

# FIXME: Come up with another idea.

class Commands::Help < Dry::CLI::Command
  Commands.register "help", self, aliases: %w[ -h --help ]

  def call(*)
    # Access the registry data
    registry_data = Command.get([])
    debug_me('== REGISTRY =='){[
      :registery_data
    ]}

    puts "super follows ..."

    supter
  end
end

