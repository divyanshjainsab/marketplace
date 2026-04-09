module Rbac
  class Access
    def initialize(user)
      @user = user
      @org_roles_by_id = nil
      @marketplace_roles_by_id = nil
    end

    attr_reader :user

    def at_least?(resource:, role:)
      return false if user.nil? || resource.nil?

      rank_for(resource) >= Registry.rank_for(role)
    end

    def organizations_scope
      return Organization.none if user.nil?

      Organization.kept
        .joins(:organization_memberships)
        .merge(OrganizationMembership.kept.where(user_id: user.id))
        .distinct
    end

    def marketplaces_scope
      return Marketplace.none if user.nil?

      org_ids = OrganizationMembership.kept.where(user_id: user.id).select(:organization_id)
      direct_ids = MarketplaceMembership.kept.where(user_id: user.id).select(:marketplace_id)

      Marketplace.kept.where(organization_id: org_ids)
        .or(Marketplace.kept.where(id: direct_ids))
        .distinct
    end

    def role_for(resource)
      case resource
      when Organization
        role_for_organization(resource)
      when Marketplace
        role_for_marketplace(resource)
      else
        nil
      end
    end

    def rank_for(resource)
      Registry.rank_for(role_for(resource))
    end

    def role_for_organization(organization)
      return nil if user.nil? || organization.nil?

      org_roles_by_id[organization.id]
    end

    def role_for_marketplace(marketplace)
      return nil if user.nil? || marketplace.nil?

      marketplace_roles_by_id[marketplace.id] || role_for_organization(marketplace.organization)
    end

    private

    def org_roles_by_id
      @org_roles_by_id ||= OrganizationMembership.kept
        .where(user_id: user.id)
        .pluck(:organization_id, :role)
        .to_h
    end

    def marketplace_roles_by_id
      @marketplace_roles_by_id ||= MarketplaceMembership.kept
        .where(user_id: user.id)
        .pluck(:marketplace_id, :role)
        .to_h
    end
  end
end
