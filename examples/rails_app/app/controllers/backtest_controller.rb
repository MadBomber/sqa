# frozen_string_literal: true

class BacktestController < ApplicationController
  def show
    @ticker = params[:ticker].upcase
    @stock = SQA::Stock.new(ticker: @ticker)
  rescue => e
    @error = "Failed to load data for #{@ticker}: #{e.message}"
    render 'errors/show', status: :unprocessable_entity
  end
end
