class ListingPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    access.at_least?(resource: marketplace_for_record, role: :manager)
  end

  def update?
    access.at_least?(resource: marketplace_for_record, role: :manager)
  end

  def destroy?
    access.at_least?(resource: marketplace_for_record, role: :admin)
  end

  class Scope < Scope
    def resolve
      return scope.kept if user.nil?
      return scope.none if Current.marketplace.nil?

      scope.kept
    end
  end

  private

  def marketplace_for_record
    if record.is_a?(Listing)
      return record.marketplace if record.marketplace.present?
      return Marketplace.kept.find_by(id: record.marketplace_id) if record.marketplace_id.present?
    end

    Current.marketplace || ActsAsTenant.current_tenant || Marketplace.kept.find_by(subdomain: ENV["DEFAULT_MARKETPLACE_SUBDOMAIN"])
  end

  def access
    @access ||= Rbac::Access.new(user)
  end
end
