# lib/sqa/indicator.rb
# frozen_string_literal: true

require 'sqa/tai'

# Delegate to SQA::TAI for all technical analysis indicators
module SQA
  module Indicator
    class << self
      # Delegate all method calls to SQA::TAI
      def method_missing(method_name, *args, **kwargs, &block)
        if SQA::TAI.respond_to?(method_name)
          SQA::TAI.send(method_name, *args, **kwargs, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        SQA::TAI.respond_to?(method_name) || super
      end
    end
  end
end

# Setup shortcuts for the namespace
SQAI = SQA::Indicator
SQATAI = SQA::TAI
