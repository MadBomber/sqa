# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception
  protect_from_forgery with: :exception

  helper_method :format_percent, :format_currency, :format_number

  private

  def format_percent(value)
    format('%.2f%%', value)
  end

  def format_currency(value)
    format('$%.2f', value)
  end

  def format_number(value)
    value.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
