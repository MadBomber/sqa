# sqa/lib/sqa/command/web.rb

module SQA::Command
	class Web
    include TTY::Option

    command "web"

    desc "Run a web server"

    example "Set working directory (-w)",
            "  sqa web --port 4567 --data-dir /path/to/dir/ ubuntu pwd"

    example <<~EOS
      Do Something
        sqa web
    EOS

    argument :image do
      required
      desc "The name of the image to use"
    end

    keyword :restart do
      default "no"
      permit %w[no on-failure always unless-stopped]
      desc "Restart policy to apply when a container exits"
    end

    flag :detach do
      long "--detach"
      desc "Run container in background and print container ID"
    end


    option :xyzzy do
      required
      long "--xyzzy string"
      desc "Assign a name to the xyzzy"
    end


    option :port do
      long    "--port int"
      convert :int
      default 4567
      desc    "The port where the web app will run"
    end


		def initialize
      # TODO: make it happen
		end


    # params is Object from TTY-Option parser
    def self.run!(params)
      if params.errors.any?
        STDERR.puts
        STDERR.puts params.errors.summary
        STDERR.puts
        return
      end

      puts <<~EOS
        ###############################
        ## Running the Web Interface ##
        ###############################
      EOS

      debug_me('WEB'){[
        "SQA.config",
        :params,
        "params.to_h",
        "params.to_h.merge(SQA.config.to_h)"
      ]}
    end
	end
end

__END__

require 'sinatra/base'

module SQA
  class Web < Sinatra::Base
    set :port, SQA.config.port || 4567

    get '/' do
      "Welcome to SQA Web Interface!"
    end


    get '/stocks/:ticker' do
      ticker  = params[:ticker]
      stock   = SQA::Stock.new(ticker: ticker, source: :alpha_vantage)

      "Stock: #{stock.data.name}, Ticker: #{stock.data.ticker}"
    end


    get '/stocks/:ticker/indicators/:indicator' do
      ticker    = params[:ticker]
      indicator = params[:indicator]
      stock     = SQA::Stock.new(ticker: ticker, source: :alpha_vantage)

      indicator_value = SQA::Indicator.send(indicator, stock.df.adj_close_price, 14)

      "Indicator #{indicator} for Stock #{ticker} is #{indicator_value}"
    end

    # TODO: Add more routes as needed to expose more functionality

    # start the server if ruby file executed directly
    run! if app_file == $0
  end
end



###################################################
#!/usr/bin/env ruby
# experiments/sinatra_examples/svg_viewer.rb
# builds on md_viewer.rb

require 'sinatra'
require 'kramdown'
require 'nenv'

# class MdViewer < Sinatra::Application

  # Set the directory location
  set :markdown_directory, Nenv.home + '/Downloads'

  # Sinatra route to show a markdown file as html
  get '/md/:filename' do
    # Get the file name from the URL parameter
    filename = params[:filename]

    # Check if the file exists in the specified directory
    if File.file?(File.join(settings.markdown_directory, filename))
      # Read the markdown file
      markdown_content = File.read(File.join(settings.markdown_directory, filename))

      # Convert the markdown to HTML using kramdown
      converted_html = Kramdown::Document.new(markdown_content).to_html

      # Display the generated HTML
      content_type :html
      converted_html
    else
      # File not found error
      status 404
      "File not found: #{filename} in #{markdown_directory}"
    end
  end


  # Sinatra route to show a markdown file as html
  get '/svg/:filename' do
    # Get the file name from the URL parameter
    filename = params[:filename]

    # Check if the file exists in the specified directory
    if File.file?(File.join(settings.markdown_directory, filename))
      # Read the svg file
      svg_content = File.read(File.join(settings.markdown_directory, filename))

      # Convert the svg to HTML
      converted_html = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>#{filename}</title>
        </head>
        <body>
          #{svg_content}
        </body>
        </html>
      HTML

      # Display the generated HTML
      content_type :html
      converted_html
    else
      # File not found error
      status 404
      "File not found: #{filename} in #{markdown_directory}"
    end
  end




# end

# Start the Sinatra app
# run MdViewer


__END__

ruby myapp.rb [-h] [-x] [-q] [-e ENVIRONMENT] [-p PORT] [-o HOST] [-s HANDLER]

Options are:

-h # help
-p # set the port (default is 4567)
-o # set the host (default is 0.0.0.0)
-e # set the environment (default is development)
-s # specify rack server/handler (default is puma)
-q # turn on quiet mode for server (default is off)
-x # turn on the mutex lock (default is off)





