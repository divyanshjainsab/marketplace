module Rbac
  class AssignRole
    def self.call(user:, resource:, role:)
      raise ArgumentError, "user is required" if user.nil?
      raise ArgumentError, "resource is required" if resource.nil?
      raise ArgumentError, "role is required" if role.nil?

      role_name = role.to_s
      raise ArgumentError, "unknown role: #{role_name}" unless Registry.known_role?(role_name)

      case resource
      when Organization
        membership = OrganizationMembership.kept.find_or_initialize_by(user_id: user.id, organization_id: resource.id)
        membership.role = role_name
        membership.save!
        membership
      when Marketplace
        membership = MarketplaceMembership.kept.find_or_initialize_by(user_id: user.id, marketplace_id: resource.id)
        membership.role = role_name
        membership.save!
        membership
      else
        raise ArgumentError, "unsupported resource type: #{resource.class.name}"
      end
    end
  end
end

