class UserSerializer < BaseSerializer
  def as_json
    roles = ["user"]
    roles << "super_admin" if record.respond_to?(:super_admin?) && record.super_admin?

    if Current.organization.present?
      access = Rbac::Access.new(record)
      roles << "org_admin" if access.at_least?(resource: Current.organization, role: :admin)
    end

    {
      id: record.id,
      external_id: record.external_id,
      email: record.email,
      name: record.name,
      roles: roles.uniq
    }
  end
end
