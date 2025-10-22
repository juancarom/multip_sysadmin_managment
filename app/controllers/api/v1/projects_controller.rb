module Api
  module V1
    class ProjectsController < BaseController
      before_action :set_project, only: [:show, :update, :destroy]

      def index
        @projects = policy_scope(Project).includes(:integrations, :users)
        
        render json: @projects.map { |p| project_json(p) }
      end

      def show
        authorize @project
        render json: project_json(@project, include_details: true)
      end

      def create
        @project = Project.new(project_params)
        authorize @project

        if @project.save
          unless current_user.superadmin?
            @project.user_projects.create!(user: current_user, role: :admin)
          end

          render json: project_json(@project), status: :created
        else
          render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize @project

        if @project.update(project_params)
          render json: project_json(@project)
        else
          render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @project
        @project.destroy
        head :no_content
      end

      private

      def set_project
        @project = Project.find_by!(slug: params[:id])
      end

      def project_params
        params.require(:project).permit(:name, :description, :active, settings: {})
      end

      def project_json(project, include_details: false)
        json = {
          id: project.id,
          slug: project.slug,
          name: project.name,
          description: project.description,
          active: project.active,
          created_at: project.created_at,
          updated_at: project.updated_at
        }

        if include_details
          json.merge!(
            integrations: project.integrations.map { |i| integration_summary(i) },
            users: project.users.map { |u| user_summary(u) },
            settings: project.settings
          )
        end

        json
      end

      def integration_summary(integration)
        {
          id: integration.id,
          type: integration.integration_type,
          name: integration.name,
          active: integration.active,
          sync_status: integration.sync_status,
          last_sync_at: integration.last_sync_at
        }
      end

      def user_summary(user)
        {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role
        }
      end
    end
  end
end
