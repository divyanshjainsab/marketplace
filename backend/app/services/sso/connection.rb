module Sso
  class Connection
    def self.client
      Faraday.new(url: ENV.fetch("SSO_BASE_URL", "http://sso:3000")) do |builder|
        builder.request :json
        builder.response :json, content_type: /\bjson$/
      end
    end
  end
end
