require 'sidekiq/web'
require 'sidekiq/cron/web'

# Mount Sidekiq web interface for monitoring
Rails.application.routes.draw do
  # Protect Sidekiq web interface
  authenticate :user, ->(user) { user.superadmin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  # ... rest of routes remain the same
end
