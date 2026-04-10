class UserSerializer < BaseSerializer
  def as_json
    {
      id: record.id,
      external_id: record.external_id,
      email: record.email,
      name: record.name,
      roles: record.respond_to?(:roles) ? record.roles : []
    }
  end
end
