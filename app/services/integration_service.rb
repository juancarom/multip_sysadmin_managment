class IntegrationService
  include ActiveModel::Model

  attr_accessor :integration, :user

  def initialize(integration, user = nil)
    @integration = integration
    @user = user
  end

  def sync!
    return false unless integration.can_sync?

    begin
      SyncIntegrationJob.perform_async(integration.id)
      true
    rescue StandardError => e
      Rails.logger.error "Failed to enqueue sync job for integration #{integration.id}: #{e.message}"
      false
    end
  end

  def toggle_active!
    integration.update!(active: !integration.active?)

    # Test connection when activating
    if integration.active? && !integration.test_connection
      integration.update!(active: false)
      return false
    end

    true
  end

  def add_user_to_external_project(user_email, project_settings = {})
    return false unless integration.active?

    begin
      integration.adapter.add_user_to_project(user_email, project_settings)
    rescue StandardError => e
      Rails.logger.error "Failed to add user to external project: #{e.message}"
      false
    end
  end

  def remove_user_from_external_project(user_email)
    return false unless integration.active?

    begin
      integration.adapter.remove_user_from_project(user_email)
    rescue StandardError => e
      Rails.logger.error "Failed to remove user from external project: #{e.message}"
      false
    end
  end

  def update_credentials!(new_credentials)
    integration.update_credentials!(new_credentials)

    # Test connection with new credentials
    raise StandardError, 'Connection test failed with new credentials' unless integration.test_connection

    true
  rescue StandardError => e
    Rails.logger.error "Failed to update credentials: #{e.message}"
    false
  end

  def get_external_users
    return [] unless integration.active?

    begin
      integration.adapter.list_users
    rescue StandardError => e
      Rails.logger.error "Failed to fetch external users: #{e.message}"
      []
    end
  end

  def validate_settings(new_settings)
    case integration.integration_type
    when 'jira'
      validate_jira_settings(new_settings)
    when 'github'
      validate_github_settings(new_settings)
    when 'gitlab'
      validate_gitlab_settings(new_settings)
    else
      { valid: false, errors: ['Unknown integration type'] }
    end
  end

  private

  def validate_jira_settings(settings)
    errors = []

    errors << 'Site domain is required' if settings['site_domain'].blank?
    errors << 'Default project key is required' if settings['default_project_key'].blank?

    { valid: errors.empty?, errors: errors }
  end

  def validate_github_settings(settings)
    errors = []

    errors << 'Organization is required' if settings['organization'].blank?
    errors << 'Default repository is required' if settings['default_repository'].blank?

    { valid: errors.empty?, errors: errors }
  end

  def validate_gitlab_settings(settings)
    errors = []

    errors << 'Base URL is required' if settings['base_url'].blank?
    errors << 'Default project ID is required' if settings['default_project_id'].blank?

    { valid: errors.empty?, errors: errors }
  end
end
