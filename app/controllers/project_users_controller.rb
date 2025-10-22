class ProjectUsersController < ApplicationController
  before_action :set_project
  before_action :authorize_project_management

  def index
    @users = @project.users.includes(:user_projects)
    @available_users = User.where.not(id: @project.users.pluck(:id))
  end

  def create
    user = User.find(params[:user_id])
    user_project = @project.user_projects.new(
      user: user,
      role: params[:role] || :member
    )

    if user_project.save
      redirect_to project_users_path(@project), 
                  notice: "#{user.name} agregado al proyecto."
    else
      redirect_to project_users_path(@project), 
                  alert: 'Error al agregar usuario al proyecto.'
    end
  end

  def destroy
    user_project = @project.user_projects.find_by!(user_id: params[:id])
    user_name = user_project.user.name
    user_project.destroy

    redirect_to project_users_path(@project), 
                notice: "#{user_name} removido del proyecto."
  end

  private

  def set_project
    @project = Project.find_by!(slug: params[:project_id])
  end

  def authorize_project_management
    authorize @project, :manage_users?
  end
end
