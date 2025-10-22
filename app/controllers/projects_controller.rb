class ProjectsController < ApplicationController
  before_action :set_project, only: %i[show edit update destroy]
  before_action :authorize_project, only: %i[show edit update destroy]

  def index
    @projects = policy_scope(Project).includes(:integrations, :users).page(params[:page])
  end

  def show
    @integrations = @project.integrations
    @users = @project.users.includes(:user_projects)
  end

  def new
    @project = Project.new
    authorize @project
  end

  def create
    @project = Project.new(project_params)
    authorize @project

    if @project.save
      # Agregar al usuario actual como admin del proyecto si no es superadmin
      @project.user_projects.create!(user: current_user, role: :admin) unless current_user.superadmin?

      redirect_to @project, notice: 'Proyecto creado exitosamente.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: 'Proyecto actualizado exitosamente.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_url, notice: 'Proyecto eliminado exitosamente.'
  end

  private

  def set_project
    @project = Project.find_by!(slug: params[:id])
  end

  def authorize_project
    authorize @project
  end

  def project_params
    params.require(:project).permit(:name, :description, :active, settings: {})
  end
end
