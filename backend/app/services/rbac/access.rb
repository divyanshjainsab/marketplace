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
      return true if super_admin?

      rank_for(resource) >= Registry.rank_for(role)
    end

    def organizations_scope
      return Organization.none if user.nil?
      return Organization.kept if super_admin?

      Organization.kept
        .joins(:organization_memberships)
        .merge(OrganizationMembership.kept.where(user_id: user.id))
        .distinct
    end

    def admin_console_organizations_scope(min_role: :staff)
      return Organization.none if user.nil?
      return Organization.kept if super_admin?

      min_rank = Registry.rank_for(min_role)
      allowed_ids = OrganizationMembership.kept
        .where(user_id: user.id)
        .pluck(:organization_id, :role)
        .filter_map do |organization_id, role_name|
          organization_id if Registry.rank_for(role_name) >= min_rank
        end
        .uniq

      Organization.kept.where(id: allowed_ids)
    end

    def admin_console_access?(organization = nil, min_role: :staff)
      return false if user.nil?
      return true if super_admin?

      if organization.present?
        return rank_for(organization) >= Registry.rank_for(min_role)
      end

      admin_console_organizations_scope(min_role: min_role).exists?
    end

    def default_organization(min_role: :staff, preferred_org_id: nil)
      scope = admin_console_organizations_scope(min_role: min_role)
      return nil unless scope.exists?

      if preferred_org_id.present?
        preferred = scope.find_by(id: preferred_org_id)
        return preferred if preferred.present?
      end

      scope.order(:name, :id).first
    end

    def marketplaces_scope
      return Marketplace.none if user.nil?
      return Marketplace.kept if super_admin?

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

    def super_admin?
      user.respond_to?(:super_admin?) ? user.super_admin? : Array(user&.roles).include?("super_admin")
    end
  end
end
