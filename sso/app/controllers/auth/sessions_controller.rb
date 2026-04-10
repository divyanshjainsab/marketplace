module Auth
  class SessionsController < Devise::SessionsController
    skip_before_action :require_no_authentication, only: [:new, :create]

    protect_from_forgery with: :exception, unless: -> { request.format.json? }

    before_action :redirect_authenticated_user!, only: :new
    before_action :ensure_login_not_rate_limited!, only: :create

    def new
      reset_pending_authentication_state!
      store_redirect_target!
      self.resource = resource_class.new(email: params.dig(resource_name, :email))
    end

    def create
      reset_pending_authentication_state!
      store_redirect_target!

      result = Auth::PasswordLogin.call(
        email: sign_in_params[:email],
        password: sign_in_params[:password]
      )

      if result.email_verification_required?
        session[:pending_email_verification_user_id] = result.user.id

        if Auth::EmailOtpService.latest_active_for(
             user: result.user,
             purpose: Auth::EmailOtpService::PURPOSE_EMAIL_VERIFICATION
           ).nil?
          Auth::EmailOtpService.issue(
            user: result.user,
            purpose: Auth::EmailOtpService::PURPOSE_EMAIL_VERIFICATION
          )
        end

        return respond_with_email_verification_required(result.user)
      end

      if result.otp_required? || result.authenticated?
        begin
          claims = Auth::LoginClaims.for(user: result.user, session: session)
          session[:pending_login_claims] = claims
        rescue Auth::LoginClaims::Denied => e
          result.message = e.message if result.respond_to?(:message=)
          return render_login_failure(
            Auth::PasswordLogin::Result.new(
              status: :invalid,
              user: nil,
              message: e.message,
              error_code: :forbidden
            )
          )
        end
      end

      if result.otp_required?
        challenge = Auth::OtpChallenge.start(
          session: session,
          user: result.user,
          return_to: current_redirect_target&.redirect_path
        )
        return respond_with_two_factor_required(result.user, challenge)
      end

      return complete_login!(result.user, claims: session[:pending_login_claims] || {}) if result.authenticated?

      render_login_failure(result)
    end

    def destroy
      reset_pending_authentication_state!

      revoke_token(request_token) if request_token.present?
      revoke_refresh_token(request_refresh_token) if request_refresh_token.present?

      cookies.delete(:sso_jwt)
      sign_out(resource_name)

      respond_to do |format|
        format.html { redirect_to login_path, notice: "Logged out" }
        format.json { head :no_content }
      end
    end

    private

    def sign_in_params
      params.fetch(resource_name, {}).permit(:email, :password, :remember_me, :return_to, :redirect_url, :redirect_uri, :state, :org_slug)
    end

    def redirect_authenticated_user!
      store_redirect_target!

      return if pending_email_verification?
      return if two_factor_pending?

      return unless user_signed_in?

      claims = Auth::LoginClaims.for(user: current_user, session: session)
      completion = complete_authenticated_session!(current_user, claims: claims)
      redirect_to completion.redirect_url, allow_other_host: true
    rescue Auth::LoginClaims::Denied => e
      sign_out(resource_name)
      reset_pending_authentication_state!
      redirect_to login_path, alert: e.message
    end

    def complete_login!(user, claims:)
      completion = complete_authenticated_session!(user, claims: claims)

      reset_pending_authentication_state!

      respond_to do |format|
        format.html do
          redirect_to completion.redirect_url, allow_other_host: true
        end
        format.json do
          render json: {
            token: completion.token_pair.access_token,
            refresh_token: completion.token_pair.refresh_token,
            exp: completion.token_pair.access_exp.to_i,
            refresh_exp: completion.token_pair.refresh_exp.to_i,
            redirect_url: completion.redirect_url,
            user: {
              external_id: user.external_id,
              email: user.email,
              name: user.name
            }
          }
        end
      end
    end


    def pending_email_verification?
      session[:pending_email_verification_user_id].present?
    end

    def two_factor_pending?
      Auth::OtpChallenge.respond_to?(:active?) &&
        Auth::OtpChallenge.active?(session: session)
    end


    def respond_with_email_verification_required(user)
      respond_to do |format|
        format.html { redirect_to verify_email_path, notice: "Verify your email address before signing in." }
        format.json do
          render json: {
            email_verification_required: true,
            verify_path: verify_email_path,
            user: { email: user.email }
          }, status: :accepted
        end
      end
    end

    def render_login_failure(result)
      self.resource = resource_class.new(email: sign_in_params[:email].to_s.strip)
      resource.errors.add(:base, result.message || "Unable to sign in.")

      respond_to do |format|
        format.html do
          flash.now[:alert] = result.message
          render :new, status: :unprocessable_entity
        end
        format.json do
          render json: { error: result.error_code || :invalid_credentials, message: result.message }, status: :unauthorized
        end
      end
    end

    def respond_with_two_factor_required(user, challenge)
      respond_to do |format|
        format.html do
          flash[:notice] = "Enter the 6-digit code from your authenticator app."
          redirect_to user_two_factor_path
        end
        format.json do
          render json: {
            two_factor_required: true,
            otp_path: user_two_factor_path,
            expires_at: challenge.expires_at.to_i,
            user: { email: user.email }
          }, status: :accepted
        end
      end
    end

    def reset_pending_authentication_state!
      Auth::OtpChallenge.clear(session: session)
      session.delete(:pending_email_verification_user_id)
      session.delete(:two_factor_recovery_user_id)
      session.delete(:pending_login_claims)
    end

    def request_token
      header = request.headers["Authorization"].to_s
      return header.split.last if header.start_with?("Bearer ")

      cookies.encrypted[:sso_jwt].to_s.presence
    end

    def request_refresh_token
      params[:refresh_token].to_s.presence
    end

    def revoke_token(token)
      decoded = Sso::JwtTokens.decode(token: token)
      JwtDenylist.create!(
        jti: decoded.payload["jti"],
        exp: Time.at(decoded.payload["exp"])
      )
    rescue JWT::DecodeError
      nil
    end

    def revoke_refresh_token(token)
      digest = Digest::SHA256.hexdigest(token)
      RefreshToken.active.find_by(token_digest: digest)&.update!(
        revoked_at: Time.current,
        revoked_reason: "logout",
        last_used_at: Time.current
      )
    end

    def ensure_login_not_rate_limited!
      email = sign_in_params[:email].to_s.downcase

      ip_result = Security::RateLimiter.check(
        key: "login:ip:#{request.remote_ip}",
        limit: 30,
        period: 300
      )

      email_result = Security::RateLimiter.check(
        key: "login:email:#{email}",
        limit: 10,
        period: 300
      )

      result = [ip_result, email_result].find { |entry| !entry.allowed? }
      return if result.nil?

      response.set_header("Retry-After", result.retry_after.to_s)

      respond_to do |format|
        format.html do
          self.resource = resource_class.new(email: sign_in_params[:email].to_s.strip)
          resource.errors.add(:base, "Too many login attempts. Try again shortly.")
          render :new, status: :too_many_requests
        end
        format.json do
          render json: { error: "rate_limited" }, status: :too_many_requests
        end
      end
    end
  end
end
