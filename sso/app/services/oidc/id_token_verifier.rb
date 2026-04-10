module Oidc
  class IdTokenVerifier
    Result = Struct.new(:ok?, :payload, :error, keyword_init: true)

    def self.verify(id_token:)
      new.verify(id_token: id_token)
    end

    def verify(id_token:)
      token = id_token.to_s
      return Result.new(ok?: false, payload: nil, error: "missing_token") if token.blank?

      public_key = SigningKey.current.private_key.public_key

      payload, = JWT.decode(
        token,
        public_key,
        true,
        {
          algorithm: "RS256",
          verify_iss: true,
          iss: Config.issuer,
          verify_aud: false
        }
      )

      aud = payload["aud"].to_s
      if aud.blank?
        return Result.new(ok?: false, payload: nil, error: "missing_audience")
      end

      begin
        ClientRegistry.fetch!(aud)
      rescue Errors::InvalidClient
        return Result.new(ok?: false, payload: nil, error: "invalid_audience")
      end

      Result.new(ok?: true, payload: payload, error: nil)
    rescue JWT::ExpiredSignature
      Result.new(ok?: false, payload: nil, error: "expired")
    rescue JWT::DecodeError
      Result.new(ok?: false, payload: nil, error: "invalid")
    end
  end
end

