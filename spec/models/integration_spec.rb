require 'rails_helper'

RSpec.describe Integration, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:integration_type) }
    it { should validate_presence_of(:name) }
    it { should validate_inclusion_of(:integration_type).in_array(%w[jira github gitlab]) }
  end

  describe 'associations' do
    it { should belong_to(:project) }
  end

  describe 'enums' do
    it { should define_enum_for(:sync_status).with_values(pending: 0, syncing: 1, completed: 2, failed: 3) }
  end

  describe '#adapter' do
    it 'returns JiraAdapter for jira integration' do
      integration = build(:integration, :jira)
      expect(integration.adapter).to be_a(IntegrationAdapters::JiraAdapter)
    end

    it 'returns GithubAdapter for github integration' do
      integration = build(:integration, :github)
      expect(integration.adapter).to be_a(IntegrationAdapters::GithubAdapter)
    end

    it 'returns GitlabAdapter for gitlab integration' do
      integration = build(:integration, :gitlab)
      expect(integration.adapter).to be_a(IntegrationAdapters::GitlabAdapter)
    end
  end

  describe '#can_sync?' do
    it 'returns true when active and has credentials and not syncing' do
      integration = create(:integration, :jira, :active)
      expect(integration.can_sync?).to be true
    end

    it 'returns false when inactive' do
      integration = create(:integration, :jira, active: false)
      expect(integration.can_sync?).to be false
    end

    it 'returns false when syncing' do
      integration = create(:integration, :jira, :active, sync_status: :syncing)
      expect(integration.can_sync?).to be false
    end
  end
end
