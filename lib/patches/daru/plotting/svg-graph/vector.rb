# lib/patches/daru/plotting/svg-graph/vector.rb

# NOTE: Code originally from Gruff
# TODO: Tailor the code to SvgGraph

module Daru
  module Plotting
    module Vector
      module SvgGraphLibrary
        def plot opts={}
          type = opts[:type] || :bar
          size = opts[:size] || 500
          case type
          when :line, :bar, :pie, :scatter, :sidebar
            plot = send("#{type}_plot", size)
          # TODO: hist, box
          # It turns out hist and box are not supported in SvgGraph yet
          else
            raise ArgumentError, 'This type of plot is not supported.'
          end
          yield plot if block_given?
          plot
        end

        private

        def line_plot size
          plot = SvgGraph::Line.new size
          plot.labels = size.times.to_a.zip(index.to_a).to_h
          plot.data name || :vector, to_a
          plot
        end

        def bar_plot size
          plot = SvgGraph::Bar.new size
          plot.labels = size.times.to_a.zip(index.to_a).to_h
          plot.data name || :vector, to_a
          plot
        end

        def pie_plot size
          plot = SvgGraph::Pie.new size
          each_with_index { |data, index| plot.data index, data }
          plot
        end

        def scatter_plot size
          plot = SvgGraph::Scatter.new size
          plot.data name || :vector, index.to_a, to_a
          plot
        end

        def sidebar_plot size
          plot = SvgGraph::SideBar.new size
          plot.labels = {0 => (name.to_s || 'vector')}
          each_with_index { |data, index| plot.data index, data }
          plot
        end
      end
    end
  end
end
