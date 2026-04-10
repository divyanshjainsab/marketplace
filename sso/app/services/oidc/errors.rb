module Oidc
  module Errors
    InvalidRequest = Class.new(StandardError)
    InvalidClient = Class.new(StandardError)
    InvalidGrant = Class.new(StandardError)
  end
end

