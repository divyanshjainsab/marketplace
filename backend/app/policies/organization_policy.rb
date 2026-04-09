class OrganizationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    access.at_least?(resource: record, role: :staff)
  end

  def create?
    user.present?
  end

  def update?
    access.at_least?(resource: record, role: :admin)
  end

  def destroy?
    access.at_least?(resource: record, role: :owner)
  end

  class Scope < Scope
    def resolve
      Rbac::Access.new(user).organizations_scope
    end
  end

  private

  def access
    @access ||= Rbac::Access.new(user)
  end
end

