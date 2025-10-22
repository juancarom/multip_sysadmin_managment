class UserPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin? || user == record
  end

  def create?
    admin?
  end

  def update?
    admin? || user == record
  end

  def destroy?
    superadmin? && user != record
  end

  def manage_role?
    superadmin? && user != record
  end

  class Scope < Scope
    def resolve
      if user.superadmin?
        scope.all
      elsif user.admin?
        # Admins can see users in their projects
        scope.joins(:user_projects)
             .where(user_projects: { project_id: user.projects.pluck(:id) })
             .distinct
      else
        scope.where(id: user.id)
      end
    end
  end
end
