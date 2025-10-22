class ScheduledSyncJob < ApplicationJob
  queue_as :scheduled

  def perform
    Rails.logger.info 'Starting scheduled sync for all active integrations'

    integrations_synced = 0
    integrations_failed = 0

    Integration.active.find_each do |integration|
      next unless integration.can_sync?

      begin
        SyncIntegrationJob.perform_async(integration.id)
        integrations_synced += 1
      rescue StandardError => e
        Rails.logger.error "Failed to enqueue sync for integration #{integration.id}: #{e.message}"
        integrations_failed += 1
      end
    end

    Rails.logger.info "Scheduled sync completed: #{integrations_synced} enqueued, #{integrations_failed} failed"
  end
end
