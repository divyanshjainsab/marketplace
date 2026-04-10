module Auth
  class SessionCookies
    ACCESS_COOKIE = ENV.fetch("BACKEND_ACCESS_COOKIE_NAME", "mp_access")
    REFRESH_COOKIE = ENV.fetch("BACKEND_REFRESH_COOKIE_NAME", "mp_refresh")

    def self.set_access!(response:, token:, expires_at:)
      set_cookie!(response: response, name: ACCESS_COOKIE, value: token, expires_at: expires_at)
    end

    def self.set_refresh!(response:, token:, expires_at:)
      set_cookie!(response: response, name: REFRESH_COOKIE, value: token, expires_at: expires_at)
    end

    def self.clear!(response:)
      set_cookie!(response: response, name: ACCESS_COOKIE, value: "", expires_at: Time.at(0))
      set_cookie!(response: response, name: REFRESH_COOKIE, value: "", expires_at: Time.at(0))
    end

    def self.read_from_cookie_header(cookie_header, name:)
      return nil if cookie_header.to_s.blank?

      parsed = Rack::Utils.parse_cookies_header(cookie_header)
      parsed[name]
    end

    def self.set_cookie!(response:, name:, value:, expires_at:)
      response.set_cookie(
        name,
        {
          value: value,
          expires: expires_at,
          httponly: true,
          secure: Rails.env.production?,
          same_site: :strict,
          path: "/",
          domain: ENV["BACKEND_SESSION_COOKIE_DOMAIN"].presence
        }.compact
      )
    end
  end
end

