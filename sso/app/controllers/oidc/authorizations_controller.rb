require "uri"

module Oidc
  class AuthorizationsController < ApplicationController
    before_action :ensure_authorize_not_rate_limited!

    def new
      request_params = authorize_params
      client = ClientRegistry.fetch!(request_params.fetch(:client_id))

      redirect_uri = request_params.fetch(:redirect_uri)
      unless client.redirect_uris.include?(redirect_uri)
        raise Errors::InvalidRequest, "invalid_redirect_uri"
      end

      unless user_signed_in?
        session[:oidc_authorization_request] = request_params.merge(requested_at: Time.current.to_i)
        return redirect_to login_path
      end

      completion = complete_authorization_for!(user: current_user, params: request_params)
      redirect_to completion, allow_other_host: true
    rescue Errors::InvalidClient
      render json: { error: "invalid_client" }, status: :unauthorized
    rescue Errors::InvalidRequest => e
      handle_authorize_error(e.message)
    end

    private

    def authorize_params
      response_type = params[:response_type].to_s
      raise Errors::InvalidRequest, "unsupported_response_type" unless response_type == "code"

      client_id = params[:client_id].to_s
      raise Errors::InvalidRequest, "missing_client_id" if client_id.blank?

      redirect_uri = params[:redirect_uri].to_s
      raise Errors::InvalidRequest, "missing_redirect_uri" if redirect_uri.blank?

      scope = params[:scope].to_s.presence || "openid profile"
      scopes = scope.split(/\s+/)
      raise Errors::InvalidRequest, "missing_openid_scope" unless scopes.include?("openid")

      state = params[:state].to_s
      raise Errors::InvalidRequest, "missing_state" if state.blank?

      nonce = params[:nonce].to_s
      raise Errors::InvalidRequest, "missing_nonce" if nonce.blank?

      code_challenge = params[:code_challenge].to_s
      raise Errors::InvalidRequest, "missing_code_challenge" if code_challenge.blank?

      method = params[:code_challenge_method].to_s
      raise Errors::InvalidRequest, "missing_code_challenge_method" if method.blank?
      raise Errors::InvalidRequest, "unsupported_code_challenge_method" unless method == "S256"

      {
        client_id: client_id,
        redirect_uri: redirect_uri,
        scope: scope,
        state: state,
        nonce: nonce,
        code_challenge: code_challenge,
        code_challenge_method: method
      }.compact
    end

    def complete_authorization_for!(user:, params:)
      claims = Auth::LoginClaims.for(user: user, session: session)
      raw_code = OidcAuthorizationCode.issue!(
        user: user,
        client_id: params.fetch(:client_id),
        redirect_uri: params.fetch(:redirect_uri),
        scope: params.fetch(:scope),
        code_challenge: params.fetch(:code_challenge),
        code_challenge_method: params.fetch(:code_challenge_method),
        nonce: params.fetch(:nonce),
        claims: claims,
        request: request
      )

      uri = URI.parse(params.fetch(:redirect_uri))
      query = Rack::Utils.parse_nested_query(uri.query)
      query["code"] = raw_code
      query["state"] = params.fetch(:state)
      uri.query = query.to_query
      uri.to_s
    rescue URI::InvalidURIError
      raise Errors::InvalidRequest, "invalid_redirect_uri"
    end

    def handle_authorize_error(code, description: nil)
      redirect_uri = params[:redirect_uri].to_s
      state = params[:state].to_s
      if redirect_uri.present?
        begin
          uri = URI.parse(redirect_uri)
          query = Rack::Utils.parse_nested_query(uri.query)
          query["error"] = "invalid_request"
          query["error_description"] = (description || code).to_s.first(200)
          query["state"] = state if state.present?
          uri.query = query.to_query
          return redirect_to uri.to_s, allow_other_host: true
        rescue URI::InvalidURIError
          # fall through
        end
      end

      render json: { error: "invalid_request", error_description: code }, status: :bad_request
    end

    def ensure_authorize_not_rate_limited!
      result = Security::RateLimiter.check(key: "authorize:ip:#{request.remote_ip}", limit: 120, period: 60)
      return if result.allowed?

      response.set_header("Retry-After", result.retry_after.to_s)
      render json: { error: "rate_limited" }, status: :too_many_requests
    end
  end
end
