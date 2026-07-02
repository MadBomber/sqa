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

desc 'Check code style with RuboCop'
task :rubocop do
  sh 'bundle exec rubocop --format simple'
end

desc 'Auto-correct RuboCop offenses'
task :rubocop_fix do
  sh 'bundle exec rubocop -A'
end

desc 'Check code complexity with Flog (warn >=20, fail >=50)'
task :flog_check do
  require 'flog'

  warn_threshold = 20.0
  fail_threshold = 50.0

  flogger = Flog.new(all: true)
  flogger.flog(*Dir.glob('lib/**/*.rb'))

  warnings = []
  failures = []

  flogger.each_by_score do |method, score|
    next if method.end_with?('#none')

    if score > fail_threshold
      failures << "#{format('%.1f', score)}: #{method}"
    elsif score > warn_threshold
      warnings << "#{format('%.1f', score)}: #{method}"
    end
  end

  unless warnings.empty?
    puts "\nFlog warnings (#{warn_threshold}–#{fail_threshold}) — target for future refactoring:"
    warnings.each { |v| puts "  #{v}" }
  end

  if failures.empty?
    puts "\nFlog: no methods exceed the failure threshold (>=#{fail_threshold})"
  else
    puts "\nFlog failures (>=#{fail_threshold}) — must be refactored:"
    failures.each { |v| puts "  #{v}" }
    abort "\nFlog quality gate failed: #{failures.size} method(s) exceed #{fail_threshold}"
  end
end

desc 'Check for structural code duplication with Flay (mass >= 50)'
task :flay_check do
  require 'flay'

  mass_threshold = 50

  flay = Flay.new(mass: mass_threshold, diff: false, verbose: false, summary: false, timeout: 60)
  flay.process(*Dir.glob('lib/**/*.rb'))
  flay.analyze

  if flay.hashes.empty?
    puts "\nFlay: no structural duplication detected (mass >= #{mass_threshold})"
  else
    puts "\nFlay found structural duplication (mass >= #{mass_threshold}):"
    flay.report
    abort "\nFlay quality gate failed: #{flay.hashes.length} pattern(s) detected"
  end
end

desc 'Run all quality checks: tests (with coverage), Flog, and Flay'
task :quality do
  results = {}

  puts "\n#{'=' * 60}"
  puts 'Quality Gate: Tests + Coverage'
  puts '=' * 60
  results[:tests] = system('bundle exec rake test') ? :pass : :fail

  puts "\n#{'=' * 60}"
  puts 'Quality Gate: Flog Complexity'
  puts '=' * 60
  results[:flog] = system('bundle exec rake flog_check') ? :pass : :fail

  puts "\n#{'=' * 60}"
  puts 'Quality Gate: Flay Duplication'
  puts '=' * 60
  results[:flay] = system('bundle exec rake flay_check') ? :pass : :fail

  puts "\n#{'=' * 60}"
  puts 'Quality Summary'
  puts '=' * 60
  results.each do |gate, status|
    icon = status == :pass ? 'PASS' : 'FAIL'
    puts "  [#{icon}] #{gate}"
  end
  puts '=' * 60

  abort "\nQuality gate failed" if results.values.any?(:fail)
  puts "\nAll quality gates passed."
end
