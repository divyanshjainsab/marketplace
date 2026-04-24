class UserSerializer < BaseSerializer
  def as_json
    roles = ["user"]
    roles << "super_admin" if record.respond_to?(:super_admin?) && record.super_admin?

    organization = context[:organization] || Current.organization
    permissions = Array(context[:permissions])
    current_role = context.key?(:current_role) ? context[:current_role] : nil

    if organization.present?
      access = Rbac::Access.new(record)
      current_role ||= access.role_for(organization)
      permissions = Rbac::Permissions.codes_for(user: record, organization: organization) if permissions.empty?
      roles << "org_admin" if access.at_least?(resource: organization, role: :admin)
      roles << current_role.to_s if current_role.present?
    end

    {
      id: record.id,
      external_id: record.external_id,
      email: record.email,
      name: record.name,
      roles: roles.map(&:to_s).reject(&:blank?).uniq,
      current_role: current_role,
      current_organization_id: organization&.id,
      permissions: permissions
    }
  end
end
