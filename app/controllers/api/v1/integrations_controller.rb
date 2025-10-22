module Api
  module V1
    class IntegrationsController < BaseController
      before_action :set_project
      before_action :set_integration, only: %i[show update destroy toggle sync]

      def index
        @integrations = @project.integrations
        render json: @integrations.map { |i| integration_json(i) }
      end

      def show
        authorize @integration
        render json: integration_json(@integration, include_details: true)
      end

      def create
        @integration = @project.integrations.new(integration_params)
        authorize @integration

        if @integration.save
          render json: integration_json(@integration), status: :created
        else
          render json: { errors: @integration.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize @integration

        if @integration.update(integration_params)
          render json: integration_json(@integration)
        else
          render json: { errors: @integration.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @integration
        @integration.destroy
        head :no_content
      end

      def toggle
        authorize @integration, :toggle?
        service = IntegrationService.new(@integration, current_user)

        if service.toggle_active!
          render json: integration_json(@integration)
        else
          render json: { error: 'No se pudo cambiar el estado' }, status: :unprocessable_entity
        end
      end

      def sync
        authorize @integration, :sync?
        service = IntegrationService.new(@integration, current_user)

        if service.sync!
          render json: { message: 'Sincronización iniciada', integration: integration_json(@integration) }
        else
          render json: { error: 'No se pudo iniciar la sincronización' }, status: :unprocessable_entity
        end
      end

      private

      def set_project
        @project = Project.find_by!(slug: params[:project_id])
      end

      def set_integration
        @integration = @project.integrations.find(params[:id])
      end

      def integration_params
        params.require(:integration).permit(
          :integration_type,
          :name,
          :active,
          settings: {},
          credentials: {}
        )
      end

      def integration_json(integration, include_details: false)
        json = {
          id: integration.id,
          project_id: integration.project_id,
          type: integration.integration_type,
          name: integration.name,
          active: integration.active,
          sync_status: integration.sync_status,
          last_sync_at: integration.last_sync_at,
          error_message: integration.error_message,
          created_at: integration.created_at,
          updated_at: integration.updated_at
        }

        if include_details
          json.merge!(
            settings: integration.settings,
            # No incluimos credentials por seguridad
            has_credentials: integration.credentials.present?
          )
        end

        json
      end
    end
  end
end
