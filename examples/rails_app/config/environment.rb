# frozen_string_literal: true

# Load the Rails application
require_relative 'application'

# Initialize SQA
require 'sqa'
SQA.init

# Initialize the Rails application
Rails.application.initialize!
