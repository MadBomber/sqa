# lib/patches/daru.rb

require_relative 'daru/category'
require_relative 'daru/data_frame'
require_relative 'daru/vector'

module Daru
	create_has_library :svg_graph

  class << self
		def plotting_library lib
			if :svg_graph = lib
				@plotting_library = lib
			else
				super
			end
		end
	end
end
