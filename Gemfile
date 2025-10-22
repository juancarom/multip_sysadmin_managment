source "https://rubygems.org"

ruby "3.0.5"

gem "rails", "~> 7.1.5"
gem "sprockets-rails"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "tzinfo-data", platforms: %i[ mswin mswin64 mingw x64_mingw jruby ]
gem "bootsnap", require: false
gem "image_processing", "~> 1.2"

# Authentication & Authorization
gem "devise"
gem "pundit"

# Background Jobs
gem "sidekiq"
gem "sidekiq-cron"
gem "redis", "~> 5.0"

# Admin
gem "activeadmin"
gem "sassc-rails"

# Integrations
gem "faraday"
gem "faraday-retry"

# Config
gem "dotenv-rails"

group :development, :test do
  gem "debug", platforms: %i[ mri mswin mswin64 mingw x64_mingw ]
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "webmock"
  gem "vcr"
  gem "shoulda-matchers"
end

group :development do
  gem "web-console"
  gem "letter_opener"
  gem "annotate"
  gem "rubocop-rails", require: false
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "database_cleaner-active_record"
end
