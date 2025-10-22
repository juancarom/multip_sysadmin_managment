FactoryBot.define do
  factory :integration do
    association :project
    integration_type { %w[jira github gitlab].sample }
    sequence(:name) { |n| "#{integration_type.capitalize} Integration #{n}" }
    active { false }
    settings { {} }
    credentials { nil }
    sync_status { :pending }

    trait :jira do
      integration_type { 'jira' }
      settings do
        {
          'site_domain' => 'example.atlassian.net',
          'default_project_key' => 'PROJ'
        }
      end
      credentials do
        {
          'access_token' => 'fake_jira_token',
          'site_domain' => 'example.atlassian.net'
        }.to_json
      end
    end

    trait :github do
      integration_type { 'github' }
      settings do
        {
          'organization' => 'example-org',
          'default_repository' => 'example-repo'
        }
      end
      credentials do
        {
          'access_token' => 'ghp_fake_token',
          'organization' => 'example-org'
        }.to_json
      end
    end

    trait :gitlab do
      integration_type { 'gitlab' }
      settings do
        {
          'base_url' => 'https://gitlab.com',
          'default_project_id' => '12345'
        }
      end
      credentials do
        {
          'access_token' => 'glpat_fake_token',
          'base_url' => 'https://gitlab.com'
        }.to_json
      end
    end

    trait :active do
      active { true }
    end

    trait :syncing do
      sync_status { :syncing }
    end

    trait :completed do
      sync_status { :completed }
      last_sync_at { Time.current }
    end

    trait :failed do
      sync_status { :failed }
      error_message { 'Connection timeout' }
    end
  end
end
