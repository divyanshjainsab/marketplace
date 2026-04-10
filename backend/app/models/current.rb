class Current < ActiveSupport::CurrentAttributes
  attribute :marketplace, :user, :request_host, :org_id, :organization
end
