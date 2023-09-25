# frozen_string_literal: true

require_relative "lib/sqa/version"

Gem::Specification.new do |spec|
  spec.name         = "sqa"
  spec.version      = SQA::VERSION
  spec.authors      = ["Dewayne VanHoozer"]
  spec.email        = ["dvanhoozer@gmail.com"]

  spec.summary      = "sqa - Stock Qualitative Analysis"
  spec.description  = "Simplistic playpen (e.g. not for serious use) for doing technical analysis of stock prices."
  spec.homepage     = "https://github.com/MadBomber/sqa"
  spec.license      = "MIT"

  spec.required_ruby_version = ">= 2.7"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"]     = spec.homepage
  spec.metadata["source_code_uri"]  = "https://github.com/MadBomber/sta"

  # spec.metadata["changelog_uri"]    = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir         = "bin"
  spec.executables    = %w[sqa]
  spec.require_paths  = %w[lib]

  spec.add_dependency 'activesupport'
  spec.add_dependency 'alphavantage' # requires hashie v4.1
  spec.add_dependency 'daru'
  spec.add_dependency 'descriptive_statistics'
  spec.add_dependency 'faraday'
  spec.add_dependency 'hashie', '~>4.1.0' # Latest version is 5.0.0
  spec.add_dependency 'nenv'
  spec.add_dependency 'sem_version'
  spec.add_dependency 'tty-option'
  spec.add_dependency 'tty-table'

  spec.add_development_dependency 'amazing_print'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'debug_me'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'rake'
end
