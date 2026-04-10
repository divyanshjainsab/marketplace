module Sso
  class OidcTokenExchange
    Result = Struct.new(:ok, :id_token, :access_token, :expires_in, :error, keyword_init: true) do
      def ok?
        ok == true
      end
    end

    def self.call(code:, client_id:, client_secret:, redirect_uri:, code_verifier:)
      new(code: code, client_id: client_id, client_secret: client_secret, redirect_uri: redirect_uri, code_verifier: code_verifier).call
    end

    def initialize(code:, client_id:, client_secret:, redirect_uri:, code_verifier:)
      @code = code.to_s
      @client_id = client_id.to_s
      @client_secret = client_secret.to_s
      @redirect_uri = redirect_uri.to_s
      @code_verifier = code_verifier.to_s
    end

    def call
      response = Connection.client.post("/token") do |req|
        req.headers["Accept"] = "application/json"
        req.body = {
          grant_type: "authorization_code",
          code: @code,
          client_id: @client_id,
          client_secret: @client_secret,
          redirect_uri: @redirect_uri,
          code_verifier: @code_verifier
        }
      end

      body = response.body.is_a?(Hash) ? response.body : {}

      if response.status == 200 && body["id_token"].present?
        return Result.new(
          ok: true,
          id_token: body["id_token"].to_s,
          access_token: body["access_token"].to_s.presence,
          expires_in: body["expires_in"].to_i,
          error: nil
        )
      end

      Result.new(ok: false, error: body["error"].presence || "token_exchange_failed:#{response.status}")
    rescue Faraday::Error => e
      Result.new(ok: false, error: "sso_unreachable:#{e.class.name}")
    end
  end
end

