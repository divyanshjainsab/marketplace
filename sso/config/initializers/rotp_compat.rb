if defined?(ROTP::TOTP) && !ROTP::TOTP.instance_methods.include?(:verify_with_drift)
  class ROTP::TOTP
    def verify_with_drift(code, drift, at: Time.current)
      verify(code, drift_behind: drift, drift_ahead: drift, at: at)
    end
  end
end
