class ProductPolicy < ApplicationPolicy
  def index?
    true
  end

  def suggestions?
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
      return scope.none if Current.marketplace.nil?

      scope.kept
        .joins(:listings)
        .merge(Listing.kept.where(marketplace_id: Current.marketplace.id))
        .distinct
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
