module Sso
  class Secrets
    def self.otp_secret_encryption_key
      ENV.fetch("OTP_SECRET_ENCRYPTION_KEY")
    end
  end
end
