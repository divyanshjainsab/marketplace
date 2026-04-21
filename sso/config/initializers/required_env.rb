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

RequiredEnv.fetch!("SSO_DATABASE_HOST")
RequiredEnv.fetch!("SSO_DATABASE_PORT")
RequiredEnv.fetch!("SSO_DATABASE_NAME")
RequiredEnv.fetch!("SSO_DATABASE_USER")
RequiredEnv.fetch!("SSO_DATABASE_PASSWORD")

RequiredEnv.fetch!("RAILS_ENV")
RequiredEnv.fetch!("RAILS_LOG_LEVEL")
RequiredEnv.fetch!("RAILS_MAX_THREADS")
RequiredEnv.fetch!("RAILS_MIN_THREADS")
RequiredEnv.fetch!("PORT")
RequiredEnv.fetch!("PIDFILE")

RequiredEnv.fetch!("SSO_APP_HOST")
RequiredEnv.fetch!("SSO_APP_PORT")
RequiredEnv.fetch!("SSO_ALLOWED_ORIGINS")
RequiredEnv.fetch!("SSO_OIDC_ISSUER")
RequiredEnv.fetch!("SSO_OIDC_ID_TOKEN_TTL_SECONDS")

RequiredEnv.fetch!("SSO_JWT_ISSUER")
RequiredEnv.fetch!("SSO_JWT_TTL_SECONDS")
RequiredEnv.fetch!("SSO_REFRESH_TOKEN_TTL_SECONDS")
RequiredEnv.fetch!("SSO_JWT_SECRET")
RequiredEnv.fetch!("OTP_SECRET_ENCRYPTION_KEY")

RequiredEnv.fetch!("SSO_ALLOWED_REDIRECT_HOSTS")
RequiredEnv.fetch!("SSO_MAILER_FROM")
RequiredEnv.fetch!("SSO_TOTP_ISSUER")

RequiredEnv.fetch!("SSO_BACKEND_BASE_URL")
RequiredEnv.fetch!("BACKEND_PUBLIC_BASE_URL")
RequiredEnv.fetch!("SSO_OIDC_ADMINFRONT_CLIENT_SECRET")
RequiredEnv.fetch!("SSO_OIDC_CLIENTFRONT_CLIENT_SECRET")
