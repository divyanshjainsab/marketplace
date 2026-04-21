class ProductTypePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    access.at_least?(resource: effective_marketplace, role: :manager)
  end

  def update?
    access.at_least?(resource: effective_marketplace, role: :manager)
  end

  def destroy?
    access.at_least?(resource: effective_marketplace, role: :admin)
  end

  class Scope < Scope
    def resolve
      scope.kept
    end
  end

  private

  def access
    @access ||= Rbac::Access.new(user)
  end

  def effective_marketplace
    Current.marketplace || ActsAsTenant.current_tenant
  end
end
