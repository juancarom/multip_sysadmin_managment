require 'rails_helper'

RSpec.describe IntegrationAdapters::JiraAdapter, type: :service do
  let(:project) { create(:project) }
  let(:integration) { create(:integration, :jira, :active, project: project) }
  let(:adapter) { integration.adapter }

  describe '#test_connection', :vcr do
    it 'returns true for valid credentials' do
      VCR.use_cassette('jira/test_connection_success') do
        expect(adapter.test_connection).to be true
      end
    end

    it 'returns false for invalid credentials' do
      integration.update!(credentials: { 'access_token' => 'invalid_token' }.to_json)

      VCR.use_cassette('jira/test_connection_failure') do
        expect(adapter.test_connection).to be false
      end
    end
  end

  describe '#sync', :vcr do
    it 'updates integration settings with sync data' do
      VCR.use_cassette('jira/sync_success') do
        result = adapter.sync
        expect(result).to be true
        expect(integration.reload.settings['last_sync_data']).to be_present
      end
    end

    it 'handles API errors gracefully' do
      integration.update!(credentials: { 'access_token' => 'invalid' }.to_json)

      VCR.use_cassette('jira/sync_failure') do
        expect { adapter.sync }.to raise_error(StandardError)
      end
    end
  end

  describe '#list_users', :vcr do
    it 'returns array of users' do
      VCR.use_cassette('jira/list_users') do
        users = adapter.list_users
        expect(users).to be_an(Array)
        expect(users.first).to have_key(:id)
        expect(users.first).to have_key(:email)
        expect(users.first).to have_key(:name)
      end
    end
  end

  describe '#add_user_to_project', :vcr do
    it 'adds user successfully' do
      VCR.use_cassette('jira/add_user') do
        result = adapter.add_user_to_project('user@example.com', { 'project_key' => 'PROJ' })
        expect(result).to be true
      end
    end

    it 'raises error when project key is missing' do
      expect do
        adapter.add_user_to_project('user@example.com')
      end.to raise_error(StandardError, /Project key not specified/)
    end
  end
end
