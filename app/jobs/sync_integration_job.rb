class SyncIntegrationJob < ApplicationJob
  queue_as :default

  def perform(integration_id)
    integration = Integration.find(integration_id)

    Rails.logger.info "Starting sync for integration #{integration.id} (#{integration.integration_type})"

    # Update status to syncing
    integration.update!(sync_status: :syncing, last_sync_at: Time.current, error_message: nil)

    begin
      # Perform the actual sync
      result = integration.adapter.sync

      if result
        integration.update!(sync_status: :completed)
        Rails.logger.info "Sync completed successfully for integration #{integration.id}"
      else
        integration.update!(sync_status: :failed, error_message: 'Sync returned false')
        Rails.logger.error "Sync failed for integration #{integration.id}"
      end
    rescue StandardError => e
      integration.update!(sync_status: :failed, error_message: e.message)
      Rails.logger.error "Sync failed for integration #{integration.id}: #{e.message}"
      raise e
    end
  end
end
