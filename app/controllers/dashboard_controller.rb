class DashboardController < ApplicationController
  def index
    @projects = current_user.accessible_projects.active.limit(5)
    @recent_integrations = Integration.joins(:project)
                                      .where(project: current_user.accessible_projects)
                                      .order(updated_at: :desc)
                                      .limit(5)
    @stats = {
      total_projects: current_user.accessible_projects.count,
      active_integrations: Integration.joins(:project)
                                      .where(project: current_user.accessible_projects, active: true)
                                      .count,
      failed_syncs: Integration.joins(:project)
                               .where(project: current_user.accessible_projects, sync_status: :failed)
                               .count
    }

    # Renderizar JSON si es una petición AJAX/API
    respond_to do |format|
      format.html
      format.json { render json: { projects: @projects, integrations: @recent_integrations, stats: @stats } }
    end
  end
end
