require "rqrcode"

module Auth
  class TotpService
    Setup = Struct.new(:secret, :qr_svg, :manual_key, keyword_init: true)

    def self.setup_for(user:, secret: nil)
      new.setup_for(user: user, secret: secret)
    end

    def self.enable_for(user:, secret:, code:)
      new.enable_for(user: user, secret: secret, code: code)
    end

    def self.verify_login(user:, code:)
      new.verify_login(user: user, code: code)
    end

    def setup_for(user:, secret: nil)
      secret = secret.presence || user.otp_secret.presence || user.class.generate_otp_secret
      totp = ROTP::TOTP.new(secret, issuer: issuer)
      svg = RQRCode::QRCode.new(
        totp.provisioning_uri(user.email)
      ).as_svg(
        offset: 0,
        color: "000000",
        shape_rendering: "crispEdges",
        module_size: 6,
        standalone: true,
        use_path: true
      )

      Setup.new(secret: secret, qr_svg: svg.html_safe, manual_key: secret)
    end

    def enable_for(user:, secret:, code:)
      return false if secret.blank?
      return false unless user.valid_otp?(normalized(code), otp_secret: secret)

      user.otp_secret = secret
      user.otp_required_for_login = true
      user.generate_otp_backup_codes! if user.respond_to?(:generate_otp_backup_codes!)
      user.save!
    end

    def verify_login(user:, code:)
      normalized_code = normalized(code)
      return true if user.valid_otp?(normalized_code)
      return false unless user.respond_to?(:invalidate_otp_backup_code!)

      user.invalidate_otp_backup_code!(normalized_code).present?
    end

    private

    def issuer
      ENV.fetch("SSO_TOTP_ISSUER")
    end

    def normalized(code)
      code.to_s.gsub(/\D/, "")
    end
  end
end
