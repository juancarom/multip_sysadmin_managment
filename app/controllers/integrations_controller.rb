class IntegrationsController < ApplicationController
  before_action :set_project, only: [:new, :create]
  before_action :set_integration, only: [:show, :edit, :update, :destroy, :toggle, :sync]
  before_action :authorize_integration, only: [:show, :edit, :update, :destroy, :toggle, :sync]

  def index
    @integrations = policy_scope(Integration).includes(:project).page(params[:page])
  end

  def show
  end

  def new
    @integration = @project.integrations.new
    authorize @integration
  end

  def create
    @integration = @project.integrations.new(integration_params)
    authorize @integration

    if @integration.save
      redirect_to [@project, @integration], notice: 'Integración creada exitosamente.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @integration.update(integration_params)
      redirect_to project_integration_path(@integration.project, @integration), 
                  notice: 'Integración actualizada exitosamente.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    project = @integration.project
    @integration.destroy
    redirect_to project_path(project), notice: 'Integración eliminada exitosamente.'
  end

  def toggle
    service = IntegrationService.new(@integration, current_user)
    
    if service.toggle_active!
      status = @integration.active? ? 'activada' : 'desactivada'
      redirect_to project_integration_path(@integration.project, @integration),
                  notice: "Integración #{status} exitosamente."
    else
      redirect_to project_integration_path(@integration.project, @integration),
                  alert: 'Error al cambiar el estado de la integración.'
    end
  end

  def sync
    service = IntegrationService.new(@integration, current_user)
    
    if service.sync!
      redirect_to project_integration_path(@integration.project, @integration),
                  notice: 'Sincronización iniciada. Los datos se actualizarán en breve.'
    else
      redirect_to project_integration_path(@integration.project, @integration),
                  alert: 'No se pudo iniciar la sincronización.'
    end
  end

  private

  def set_project
    @project = Project.find_by!(slug: params[:project_id])
  end

  def set_integration
    @integration = Integration.find(params[:id])
  end

  def authorize_integration
    authorize @integration
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
end
