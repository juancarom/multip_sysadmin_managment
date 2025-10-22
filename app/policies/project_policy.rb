class ProjectPolicy < ApplicationPolicy
  def index?
    user_signed_in?
  end

  def show?
    user_signed_in? && (admin? || user_has_access?)
  end

  def create?
    admin?
  end

  def update?
    admin? || user_is_project_admin?
  end

  def destroy?
    superadmin?
  end

  def manage_users?
    admin? || user_is_project_admin?
  end

  def manage_integrations?
    admin? || user_is_project_admin?
  end

  class Scope < Scope
    def resolve
      if user.superadmin?
        scope.all
      else
        user.accessible_projects
      end
    end
  end

  private

  def user_has_access?
    return false unless user_signed_in?

    user.accessible_projects.include?(record)
  end

  def user_is_project_admin?
    return false unless user_signed_in?

    user.user_projects.where(project: record, role: :admin).exists?
  end
end
