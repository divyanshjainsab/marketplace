class Current < ActiveSupport::CurrentAttributes
  attribute :marketplace, :user, :request_host
end
