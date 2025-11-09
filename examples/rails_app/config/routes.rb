# frozen_string_literal: true

Rails.application.routes.draw do
  # Root route
  root 'dashboard#index'

  # Dashboard routes
  get 'dashboard/:ticker', to: 'dashboard#show', as: :stock_dashboard
  get 'analyze/:ticker', to: 'analysis#show', as: :stock_analysis
  get 'backtest/:ticker', to: 'backtest#show', as: :stock_backtest
  get 'portfolio', to: 'portfolio#index', as: :portfolio

  # API routes
  namespace :api do
    namespace :v1 do
      get 'stock/:ticker', to: 'stocks#show'
      get 'indicators/:ticker', to: 'stocks#indicators'
      post 'backtest/:ticker', to: 'stocks#backtest'
      get 'analyze/:ticker', to: 'stocks#analyze'
      post 'compare/:ticker', to: 'stocks#compare'
    end
  end

  # Health check
  get 'up', to: 'rails/health#show', as: :rails_health_check
end
