# lib/patches/daru/plotting/svg-graph/vector.rb

# NOTE: Code originally from Gruff
# TODO: Tailor the code to SvgGraph

module Daru
  module Plotting
    module Vector
      module SvgGraphLibrary
        def plot opts={}
          opts[:type]   ||= :line
          opts[:size]   ||= 500   # SMELL: What is this?
          opts[:height] ||= 720
          opts[:width]  ||= 720
          opts[:title]  ||= name || :vector

          debug_me{[
            :opts,
            :self
          ]}

          if %i[line bar pie scatter sidebar].include? type
            graph = send("#{type}_plot", opts)
          else
            raise ArgumentError, 'This type of plot is not supported.'
          end

          yield graph if block_given?

          graph
        end

        private

        ####################################################
        def line_plot opts={}
          graph  = SVG::Graph::Line.new opts

          graph.add_data(
            data:   to_a,
            title:  opts[:title]
          )

          graph
        end


        ####################################################
        def bar_plot opts
          graph  = SVG::Graph::Bar.new opts

          graph.add_data(
            data:   to_a,
            title:  opts[:title]
          )

          graph
        end


        ####################################################
        def pie_plot opts
          graph  = SVG::Graph::Pie.new opts

          graph.add_data(
            data:   to_a,
            title:  opts[:title]
          )

          graph
        end


        ####################################################
        def scatter_plot size
          graph  = SVG::Graph::Plot.new opts


          graph.add_data(
            data:   to_a.zip(index.to_a)
            title:  opts[:title]
          )

          graph
        end


        ####################################################
        def sidebar_plot size
          graph  = SVG::Graph::BarHorizontal.new opts

          graph.add_data(
            data:   to_a,
            title:  opts[:title]
          )

          graph
        end
      end
    end
  end
end
