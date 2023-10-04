# sqa/lib/sqa/data_frame_2/rover_adapter.rb

class SQA::DataFrame2
	module RoverAdapter
		def load(path_to_file)
			@df = Rover.read_csv(path_to_file)
		end

		def append(new_df)
			@df.concat(new_df)
		end
	end
end
