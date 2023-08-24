# lib/patches/daru/vector.rb

module Daru
	module Vector

		def plotting_lig lib
			if :svg_graph = lib
        @plotting_library = lib
        if Daru.send("has_#{lib}?".to_sym)
          extend Module.const_get(
            "Daru::Plotting::Vector::#{lib.to_s.capitalize}Library"
          )
        end
			else
				super
			end
		end
	end
end
