# frozen_string_literal: true

begin
  require 'tocer/rake/register'
rescue LoadError => e
  puts e.message
end

Tocer::Rake::Register.call

begin
  require 'yard'

  namespace :docs do
    desc 'Build complete documentation site (API markdown + MkDocs)'
    task :build do
      puts 'Step 1: Generating API documentation from YARD comments...'
      sh 'ruby bin/generate_api_docs.rb'

      puts "\nStep 2: Building MkDocs site with Material theme..."
      sh 'mkdocs build'

      puts "\nDocumentation complete!"
      puts '  Site: site/index.html'
      puts '  API Reference: site/api-reference/index.html'
      puts "\nTo preview: rake docs:serve"
    end

    desc 'Serve documentation locally with live reload'
    task :serve do
      puts 'Starting MkDocs development server...'
      puts 'View at: http://127.0.0.1:8000'
      puts 'Press Ctrl+C to stop'
      sh 'mkdocs serve'
    end

    desc 'Clean generated documentation files'
    task :clean do
      puts 'Cleaning generated documentation...'
      sh 'rm -rf docs/api-reference site .yardoc'
      puts 'Done!'
    end

    desc 'Deploy documentation to GitHub Pages'
    task deploy: :build do
      puts "\nDeploying to GitHub Pages..."
      sh 'mkdocs gh-deploy --force'

      puts "\nDeployment complete!"
      puts 'Documentation is live at: https://madbomber.github.io/sqa/'
    end
  end
rescue LoadError
  # YARD not available
end

require 'bundler/gem_tasks'
require 'minitest/test_task'

Minitest::TestTask.create(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.warning = false
  t.test_globs = ['test/**/*_test.rb']
end

task default: %i[]
