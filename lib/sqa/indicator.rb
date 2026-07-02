# lib/sqa/indicator.rb
# frozen_string_literal: true

# Try to load TA-Lib indicators, but make them optional
# This allows the library to work without TA-Lib installed for basic data loading
begin
  require 'sqa/tai'

  # Use SQA::TAI directly for all technical analysis indicators
  # SQAI is a shortcut alias for SQA::TAI
  SQAI = SQA::TAI
rescue LoadError, Fiddle::DLError => e
  # TA-Lib not available - define a stub that gives helpful errors
  warn "Warning: TA-Lib not available (#{e.class}: #{e.message}). Technical indicators will not work." if $VERBOSE

  module SQAI
    def self.method_missing(method, *args, &)
      raise "Technical indicators require TA-Lib to be installed. Please install libta-lib system library. Visit: http://ta-lib.org/hdr_dw.html"
    end

    def self.respond_to_missing?(method, include_private = false)
      false
    end
  end
end
