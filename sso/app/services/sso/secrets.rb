module Sso
  class Secrets
    def self.otp_secret_encryption_key
      ENV["OTP_SECRET_ENCRYPTION_KEY"].presence ||
        Rails.application.credentials.dig(:sso, :otp_secret_encryption_key) ||
        raise(KeyError, 'missing OTP_SECRET_ENCRYPTION_KEY (or credentials.sso.otp_secret_encryption_key)')
    end
  end
end
