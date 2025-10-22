class UserProjectSyncJob < ApplicationJob
  queue_as :default

  def perform(user_project_id, action = 'add')
    user_project = UserProject.find(user_project_id)
    user = user_project.user
    project = user_project.project

    Rails.logger.info "Syncing user #{user.email} #{action} to project #{project.name} integrations"

    project.active_integrations.find_each do |integration|
      service = IntegrationService.new(integration)

      case action.to_s
      when 'add'
        service.add_user_to_external_project(user.email)
      when 'remove'
        service.remove_user_from_external_project(user.email)
      end

      Rails.logger.info "Successfully synced user #{user.email} #{action} for #{integration.integration_type}"
    rescue StandardError => e
      Rails.logger.error "Failed to sync user #{user.email} #{action} for integration #{integration.id}: #{e.message}"
    end
  end
end
