# == Schema Information
#
# Table name: integrations
#
#  id               :bigint           not null, primary key
#  project_id       :bigint           not null
#  integration_type :string           not null
#  name             :string           not null
#  active           :boolean          default(false), not null
#  settings         :json
#  credentials      :text             # encrypted
#  last_sync_at     :datetime
#  sync_status      :integer          default("pending")
#  error_message    :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class Integration < ApplicationRecord
  belongs_to :project

  INTEGRATION_TYPES = %w[jira github gitlab].freeze

  enum sync_status: { pending: 0, syncing: 1, completed: 2, failed: 3 }

  validates :integration_type, presence: true, inclusion: { in: INTEGRATION_TYPES }
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :integration_type, uniqueness: { scope: :project_id }

  encrypts :credentials

  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(integration_type: type) }

  def adapter
    @adapter ||= case integration_type
                 when 'jira'
                   IntegrationAdapters::JiraAdapter.new(self)
                 when 'github'
                   IntegrationAdapters::GithubAdapter.new(self)
                 when 'gitlab'
                   IntegrationAdapters::GitlabAdapter.new(self)
                 else
                   raise "Unknown integration type: #{integration_type}"
                 end
  end

  def sync!
    return false unless active?

    update!(sync_status: :syncing, last_sync_at: Time.current, error_message: nil)

    begin
      result = adapter.sync
      update!(sync_status: :completed)
      result
    rescue StandardError => e
      update!(sync_status: :failed, error_message: e.message)
      false
    end
  end

  def test_connection
    return false unless credentials.present?

    adapter.test_connection
  rescue StandardError => e
    Rails.logger.error "Integration #{id} connection test failed: #{e.message}"
    false
  end

  def formatted_credentials
    return {} if credentials.blank?

    JSON.parse(credentials)
  rescue JSON::ParserError
    {}
  end

  def update_credentials!(new_credentials)
    update!(credentials: new_credentials.to_json)
  end

  def can_sync?
    active? && credentials.present? && !syncing?
  end
end
