if defined?(ROTP::TOTP) && !ROTP::TOTP.instance_methods.include?(:verify_with_drift)
  class ROTP::TOTP
    def verify_with_drift(code, drift, at: Time.current)
      # ROTP 6.3+ requires the OTP input to be a String. Treat missing/blank OTP
      # as a simple verification failure (nil) rather than raising during view
      # rendering or warden strategy evaluation.
      code = code.to_s
      return nil if code.blank?

      verify(code, drift_behind: drift, drift_ahead: drift, at: at)
    end
  end
end
