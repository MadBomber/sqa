# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_cable/railtie'
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile
Bundler.require(*Rails.groups)

module SqaRailsApp
  class Application < Rails::Application
    # Initialize configuration defaults for Rails 7.1
    config.load_defaults 7.1

    # Configuration for the application, engines, and railties
    config.autoload_lib(ignore: %w(assets tasks))

    # Add SQA library to load path
    lib_path = File.expand_path('../../../lib', __dir__)
    $LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)

    # API-only mode for API namespace
    config.api_only = false

    # Enable sessions
    config.session_store :cookie_store, key: '_sqa_rails_session'

    # Assets
    config.assets.paths << Rails.root.join('app', 'assets', 'stylesheets')
    config.assets.paths << Rails.root.join('app', 'assets', 'javascripts')

    # Time zone
    config.time_zone = 'UTC'

    # Eager load in production
    config.eager_load = Rails.env.production?
  end
end
