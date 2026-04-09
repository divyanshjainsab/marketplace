class UserSerializer < BaseSerializer
  def as_json
    {
      id: record.id,
      external_id: record.external_id,
      email: record.email,
      name: record.name
    }
  end
end
