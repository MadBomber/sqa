# .../sqa/cli/commands/version.rb


class Commands::Version < Commands::Base
  Commands.register "version", self, aliases: %w[--version]

  desc "Print version"

  def initialize(version=SQA::VERSION)
    @version = version
  end


  # Don't care about any arguments, just
  # print the version to STDOUT and exit

  def call(*)
    puts @version
    exit(0)
  end
end

# Create a short-cut to the class
PrintVersion = Commands::Version
