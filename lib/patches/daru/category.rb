# lib/patches/daru/category.rb

module Daru
	module Category

		def plotting_lig lib
			if :svg_graph = lib
        @plotting_library = lib
        if Daru.send("has_#{lib}?".to_sym)
          extend Module.const_get(
            "Daru::Plotting::Category::#{lib.to_s.capitalize}Library"
          )
        end
			else
				super
			end
		end
	end
end
