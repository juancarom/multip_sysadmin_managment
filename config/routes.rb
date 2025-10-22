require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users

  # Root
  root 'dashboard#index'

  # Sidekiq Web (solo superadmin)
  authenticate :user, ->(user) { user.superadmin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  # Admin interface (configurar después con ActiveAdmin)
  # ActiveAdmin.routes(self)

  # API routes
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :projects do
        resources :integrations do
          member do
            patch :toggle
            post :sync
          end
        end
        resources :users, only: %i[index create destroy]
      end
      resources :users, only: %i[show update]
    end
  end

  # Main application routes
  resources :projects do
    resources :integrations do
      member do
        patch :toggle
        post :sync
      end
    end
    resources :users, only: %i[index create destroy], controller: 'project_users'
  end

  resources :integrations, only: %i[index show edit update]
  resources :users, only: %i[show edit update]

  # Health check
  get 'up' => 'rails/health#show', as: :rails_health_check
  get '/health', to: 'application#health'
end
