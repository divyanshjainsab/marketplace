module Auth
  class OidcState
    TTL = 10.minutes

    def self.issue(payload)
      new.issue(payload)
    end

    def self.verify(state)
      new.verify(state)
    end

    def initialize
      secret = ENV.fetch("BACKEND_OIDC_STATE_SECRET")
      @verifier = ActiveSupport::MessageVerifier.new(secret, digest: "SHA256", serializer: JSON)
    end

    def issue(payload)
      now = Time.current.to_i
      data = payload.merge("iat" => now, "exp" => now + TTL.to_i)
      @verifier.generate(data)
    end

    def verify(state)
      data = @verifier.verify(state.to_s)
      exp = Integer(data.fetch("exp"))
      raise ActiveSupport::MessageVerifier::InvalidSignature if Time.current.to_i > exp
      data
    rescue KeyError, ArgumentError, ActiveSupport::MessageVerifier::InvalidSignature
      raise ActiveSupport::MessageVerifier::InvalidSignature
    end
  end
end

