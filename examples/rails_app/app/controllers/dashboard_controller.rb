# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    # Landing page
  end

  def show
    @ticker = params[:ticker].upcase
    load_stock_data
  rescue => e
    @error = "Failed to load data for #{@ticker}: #{e.message}"
    render 'errors/show', status: :unprocessable_entity
  end

  private

  def load_stock_data
    @stock = SQA::Stock.new(ticker: @ticker)
  end
end
