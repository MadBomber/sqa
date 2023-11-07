# lib/sqa/cli.rb

require 'dry/cli'

require_relative '../sqa'
require_relative 'commands'

module SQA::CLI
  class << self
    def run!
      Dry::CLI.new(SQA::Commands).call
    end
  end
end




__END__




    # header "Stock Quantitative Analysis (SQA)"
    # footer "WARNING: This is a toy, a play thing, not intended for serious use."

    # program "sqa"
    # desc    "A collection of things"




    class << self

      ##################################################
      def run(argv = ARGV)


        elsif params[:dump_config]
          SQA.config.config_file  = params[:dump_config]
          `touch #{SQA.config.config_file}`
          SQA.config.dump_file
          exit(0)

        elsif params[:config_file]
          # Override the defaults <- envars <- config file content
          params[:config_file]   = SQA.homify params[:config_file]
          SQA.config.config_file = params[:config_file]
          SQA.config.from_file
        end



        # Override the defaults <- envars <- config file <- cli parameters
        SQA.config.merge!(remove_temps params.to_h)


      end
    end
	end
end

