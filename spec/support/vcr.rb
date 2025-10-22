# VCR configuration for recording HTTP interactions
VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.ignore_localhost = true

  # Filter sensitive data
  config.filter_sensitive_data('<JIRA_TOKEN>') { ENV['JIRA_ACCESS_TOKEN'] }
  config.filter_sensitive_data('<GITHUB_TOKEN>') { ENV['GITHUB_ACCESS_TOKEN'] }
  config.filter_sensitive_data('<GITLAB_TOKEN>') { ENV['GITLAB_ACCESS_TOKEN'] }

  # Allow requests to local Rails server
  config.ignore_hosts 'localhost', '127.0.0.1', '0.0.0.0'
end

# WebMock configuration
WebMock.disable_net_connect!(allow_localhost: true)
