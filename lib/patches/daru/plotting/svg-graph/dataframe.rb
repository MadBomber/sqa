# lib/patches/daru/plotting/svg-graph/dataframe.rb

# NOTE: Code originally from Gruff
# TODO: Tailor the code to SvgGraph

module Daru
  module Plotting
    module DataFrame
      module SvgGraphLibrary
        def plot opts={}
          opts[:type] ||= :line
          opts[:size] ||= 500

          x     = extract_x_vector  opts[:x]
          y     = extract_y_vectors opts[:y]

          opts[:type]  = process_type opts[:type], opts[:categorized]

          type = opts[:type]

          if %o[line bar scatter].include? type
            graph = send("#{type}_plot", size, x, y)

          elsif :scatter_categorized == type
            graph = scatter_with_category(size, x, y, opts[:categorized])

          else
            raise ArgumentError, 'This type of plot is not supported.'
          end

          yield graph if block_given?
          graph
        end

        private

        def process_type type, categorized
          type == :scatter && categorized ? :scatter_categorized : type
        end

        ##########################################################
        def line_plot size, x, y
          plot = SvgGraph::Line.new size
          plot.labels = size.times.to_a.zip(x).to_h
          y.each do |vec|
            plot.data vec.name || :vector, vec.to_a
          end
          plot
        end

        ##########################################################
        def bar_plot size, x, y
          plot = SvgGraph::Bar.new size
          plot.labels = size.times.to_a.zip(x).to_h
          y.each do |vec|
            plot.data vec.name || :vector, vec.to_a
          end
          plot
        end

        ##########################################################
        def scatter_plot size, x, y
          plot = SvgGraph::Scatter.new size
          y.each do |vec|
            plot.data vec.name || :vector, x, vec.to_a
          end
          plot
        end

        ##########################################################
        def scatter_with_category size, x, y, opts
          x       = Daru::Vector.new x
          y       = y.first
          plot    = SvgGraph::Scatter.new size
          cat_dv  = self[opts[:by]]

          cat_dv.categories.each do |cat|
            bools = cat_dv.eq cat
            plot.data cat, x.where(bools).to_a, y.where(bools).to_a
          end

          plot
        end

        def extract_x_vector x_name
          x_name && self[x_name].to_a || index.to_a
        end

        def extract_y_vectors y_names
          y_names =
            case y_names
            when nil
              vectors.to_a
            when Array
              y_names
            else
              [y_names]
            end

          y_names.map { |y| self[y] }.select(&:numeric?)
        end
      end
    end
  end
end
