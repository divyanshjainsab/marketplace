module RequiredEnv
  module_function

  def fetch!(key, allow_blank: false)
    value = ENV.fetch(key)
    if !allow_blank && value.to_s.strip.empty?
      raise KeyError, "Missing required environment variable: #{key}"
    end
    value
  rescue KeyError
    raise KeyError, "Missing required environment variable: #{key}"
  end
end

RequiredEnv.fetch!("BACKEND_DATABASE_HOST")
RequiredEnv.fetch!("BACKEND_DATABASE_PORT")
RequiredEnv.fetch!("BACKEND_DATABASE_NAME")
RequiredEnv.fetch!("BACKEND_DATABASE_USER")
RequiredEnv.fetch!("BACKEND_DATABASE_PASSWORD")

RequiredEnv.fetch!("RAILS_ENV")
RequiredEnv.fetch!("RAILS_LOG_LEVEL")
RequiredEnv.fetch!("RAILS_MAX_THREADS")
RequiredEnv.fetch!("RAILS_MIN_THREADS")
RequiredEnv.fetch!("PORT")
RequiredEnv.fetch!("PIDFILE")

RequiredEnv.fetch!("SSO_BASE_URL")
RequiredEnv.fetch!("SSO_PUBLIC_BASE_URL")
RequiredEnv.fetch!("SSO_OIDC_ISSUER")

RequiredEnv.fetch!("BACKEND_PUBLIC_BASE_URL")
RequiredEnv.fetch!("CLIENTFRONT_BASE_URL")
RequiredEnv.fetch!("ADMINFRONT_BASE_URL")

RequiredEnv.fetch!("SSO_OIDC_ADMINFRONT_CLIENT_SECRET")
RequiredEnv.fetch!("SSO_OIDC_CLIENTFRONT_CLIENT_SECRET")

RequiredEnv.fetch!("BACKEND_ACCESS_COOKIE_NAME")
RequiredEnv.fetch!("BACKEND_REFRESH_COOKIE_NAME")
RequiredEnv.fetch!("BACKEND_SESSION_AUDIENCE")
RequiredEnv.fetch!("BACKEND_SESSION_ISSUER")
RequiredEnv.fetch!("BACKEND_SESSION_TTL_SECONDS")
RequiredEnv.fetch!("BACKEND_SESSION_JWT_KEYS")
RequiredEnv.fetch!("BACKEND_SESSION_JWT_CURRENT_KID")
RequiredEnv.fetch!("BACKEND_REFRESH_TTL_SECONDS")
RequiredEnv.fetch!("BACKEND_OIDC_STATE_SECRET")

RequiredEnv.fetch!("BACKEND_AUTH_REQUIRED")
RequiredEnv.fetch!("BACKEND_TENANT_REQUIRED")
RequiredEnv.fetch!("BACKEND_TRUST_FORWARDED_HOST")
