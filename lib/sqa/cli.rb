# lib/sqa/cli.rb

module SQA
	class CLI
		def initialize
			@args = $ARGV.dup
		end

		def run
			puts <<~OUTPUT

				sqa was called with the following options:

				#{@args}

			OUTPUT
		end
	end
end
