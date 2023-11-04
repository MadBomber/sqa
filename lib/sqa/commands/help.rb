# .../sqa/cli/commands/help.rb

# Override the default dry-cli help command
# SMELL: Dry::CLI can not be over-ridden

# FIXME: Come up with another idea.

class Commands::Help < Dry::CLI::Command
  Command.register "help", self, aliases: %w[ -h --help ]

  def call(*)
    puts "== header =="

    # Access the registry data
    registry_data = Command.get([])
    debug_me('== REGISTRY =='){[
      :registery_data
    ]}

    puts "supper follows ..."

    supter
    puts "== footer =="
  end
end

