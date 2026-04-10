module Oidc
  class TokensController < ApplicationController
    protect_from_forgery with: :null_session
    before_action :ensure_token_not_rate_limited!

    def create
      payload = token_params

      raise Errors::InvalidRequest, "unsupported_grant_type" unless payload[:grant_type] == "authorization_code"

      client = ClientRegistry.fetch!(payload[:client_id])
      if client.confidential?
        provided = payload[:client_secret].to_s
        expected = client.client_secret.to_s
        raise Errors::InvalidClient, "invalid_client_secret" unless expected.present? && provided.present? &&
          ActiveSupport::SecurityUtils.secure_compare(expected, provided)
      end

      unless client.redirect_uris.include?(payload[:redirect_uri])
        raise Errors::InvalidRequest, "invalid_redirect_uri"
      end

      record = nil
      OidcAuthorizationCode.transaction do
        record = OidcAuthorizationCode.consume!(
          code: payload[:code],
          client_id: payload[:client_id],
          redirect_uri: payload[:redirect_uri]
        )

        Pkce.verify!(
          verifier: payload[:code_verifier],
          expected_challenge: record.code_challenge,
          method: record.code_challenge_method
        )

        record.update!(used_at: Time.current)
      end

      id_token = IdTokens.issue(
        user: record.user,
        client_id: record.client_id,
        nonce: record.nonce,
        claims: record.claims
      )

      # Optional opaque access token (kept for compatibility; not used by our Resource Server).
      access_token = SecureRandom.hex(32)

      render json: {
        token_type: "Bearer",
        expires_in: Config.id_token_ttl_seconds,
        access_token: access_token,
        id_token: id_token
      }
    rescue Errors::InvalidClient => e
      render json: { error: "invalid_client", error_description: e.message }, status: :unauthorized
    rescue Errors::InvalidGrant => e
      render json: { error: "invalid_grant", error_description: e.message }, status: :bad_request
    rescue Errors::InvalidRequest => e
      render json: { error: "invalid_request", error_description: e.message }, status: :bad_request
    rescue ActiveRecord::RecordNotFound
      render json: { error: "invalid_grant", error_description: "unknown_code" }, status: :bad_request
    end

    private

    def token_params
      body = if request.content_mime_type&.json?
        request.request_parameters
      else
        params
      end

      grant_type = body[:grant_type].to_s.presence || "authorization_code"
      code = body[:code].to_s
      client_id = body[:client_id].to_s
      redirect_uri = body[:redirect_uri].to_s
      code_verifier = body[:code_verifier].to_s

      raise Errors::InvalidRequest, "missing_code" if code.blank?
      raise Errors::InvalidRequest, "missing_client_id" if client_id.blank?
      raise Errors::InvalidRequest, "missing_redirect_uri" if redirect_uri.blank?
      raise Errors::InvalidRequest, "missing_code_verifier" if code_verifier.blank?

      {
        grant_type: grant_type,
        code: code,
        client_id: client_id,
        client_secret: body[:client_secret].to_s,
        redirect_uri: redirect_uri,
        code_verifier: code_verifier
      }
    end

    def ensure_token_not_rate_limited!
      result = Security::RateLimiter.check(key: "oidc_token:ip:#{request.remote_ip}", limit: 120, period: 60)
      return if result.allowed?

      response.set_header("Retry-After", result.retry_after.to_s)
      render json: { error: "rate_limited" }, status: :too_many_requests
    end
  end
end

