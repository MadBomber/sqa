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

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

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

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
end
