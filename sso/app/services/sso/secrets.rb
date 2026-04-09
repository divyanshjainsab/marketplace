module Sso
  class Secrets
    def self.otp_secret_encryption_key
      ENV["OTP_SECRET_ENCRYPTION_KEY"].presence ||
        Rails.application.credentials.dig(:sso, :otp_secret_encryption_key) ||
        raise(KeyError, 'missing OTP_SECRET_ENCRYPTION_KEY (or credentials.sso.otp_secret_encryption_key)')
    end

    def self.jwt_secret
      ENV["SSO_JWT_SECRET"].presence ||
        Rails.application.credentials.dig(:sso, :jwt_secret) ||
        raise(KeyError, 'missing SSO_JWT_SECRET (or credentials.sso.jwt_secret)')
    end

    def self.jwt_issuer
      ENV["SSO_JWT_ISSUER"].presence ||
        Rails.application.credentials.dig(:sso, :jwt_issuer) ||
        "sso"
    end

    def self.jwt_ttl_seconds
      (ENV["SSO_JWT_TTL_SECONDS"].presence ||
        Rails.application.credentials.dig(:sso, :jwt_ttl_seconds) ||
        3600).to_i
    end

    def self.refresh_token_ttl_seconds
      (ENV["SSO_REFRESH_TOKEN_TTL_SECONDS"].presence ||
        Rails.application.credentials.dig(:sso, :refresh_token_ttl_seconds) ||
        30.days.to_i).to_i
    end
  end
end
