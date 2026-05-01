class Current < ActiveSupport::CurrentAttributes
  attribute :marketplace,
            :user,
            :request_host,
            :org_id,
            :organization,
            :session_org_id,
            :session_roles,
            :request_id,
            :remote_ip,
            :user_agent
end
