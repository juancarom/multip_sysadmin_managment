class IntegrationPolicy < ApplicationPolicy
  def index?
    user_signed_in?
  end

  def show?
    user_signed_in? && user_has_project_access?
  end

  def create?
    admin? || user_is_project_admin?
  end

  def update?
    admin? || user_is_project_admin?
  end

  def destroy?
    admin? || user_is_project_admin?
  end

  def toggle?
    admin? || user_is_project_admin?
  end

  def sync?
    (admin? || user_is_project_admin?) && record.can_sync?
  end

  def manage_credentials?
    admin? || user_is_project_admin?
  end

  class Scope < Scope
    def resolve
      if user.superadmin?
        scope.all
      else
        scope.joins(:project).where(project: user.accessible_projects)
      end
    end
  end

  private

  def user_has_project_access?
    return false unless user_signed_in?

    user.accessible_projects.include?(record.project)
  end

  def user_is_project_admin?
    return false unless user_signed_in?

    user.user_projects.where(project: record.project, role: :admin).exists?
  end
end
