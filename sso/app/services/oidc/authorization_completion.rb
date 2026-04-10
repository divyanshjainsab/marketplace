require "uri"

module Oidc
  class AuthorizationCompletion
    Result = Struct.new(:redirect_url, keyword_init: true)

    REQUEST_TTL = 10.minutes

    def self.call(user:, request:, session_request:, claims:)
      new(user: user, request: request, session_request: session_request, claims: claims).call
    end

    def initialize(user:, request:, session_request:, claims:)
      @user = user
      @request = request
      @session_request = (session_request || {}).stringify_keys
      @claims = claims || {}
    end

    def call
      requested_at = @session_request["requested_at"].to_i
      if requested_at > 0 && Time.at(requested_at) < REQUEST_TTL.ago
        return Result.new(redirect_url: "/")
      end

      client_id = @session_request.fetch("client_id")
      redirect_uri = @session_request.fetch("redirect_uri")
      scope = @session_request.fetch("scope")
      state = @session_request.fetch("state")
      nonce = @session_request.fetch("nonce")
      code_challenge = @session_request.fetch("code_challenge")
      code_challenge_method = @session_request.fetch("code_challenge_method")

      client = ClientRegistry.fetch!(client_id)
      return Result.new(redirect_url: "/") unless client.redirect_uris.include?(redirect_uri)

      raw_code = OidcAuthorizationCode.issue!(
        user: user,
        client_id: client_id,
        redirect_uri: redirect_uri,
        scope: scope,
        code_challenge: code_challenge,
        code_challenge_method: code_challenge_method,
        nonce: nonce,
        claims: claims,
        request: request
      )

      uri = URI.parse(redirect_uri)
      query = Rack::Utils.parse_nested_query(uri.query)
      query["code"] = raw_code
      query["state"] = state
      uri.query = query.to_query

      Result.new(redirect_url: uri.to_s)
    rescue KeyError
      Result.new(redirect_url: "/")
    rescue URI::InvalidURIError
      Result.new(redirect_url: "/")
    end

    private

    attr_reader :user, :request, :claims
  end
end

