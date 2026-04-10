module Auth
  class EmailVerificationsController < ApplicationController
    before_action :redirect_verified_user!, only: %i[show create resend]
    before_action :load_pending_user!
    before_action :ensure_resend_not_rate_limited!, only: :resend

    def show
    end

    def create
      result = Auth::EmailOtpService.verify(
        user: @user,
        purpose: Auth::EmailOtpService::PURPOSE_EMAIL_VERIFICATION,
        code: params[:otp_attempt]
      )

      unless result.ok?
        return handle_failed_verification(result)
      end

      @user.update!(email_verified: true)
      session.delete(:pending_email_verification_user_id)
      if @user.otp_required_for_login?
        claims = Auth::LoginClaims.for(user: @user, session: session)
        session[:pending_login_claims] = claims
        Auth::OtpChallenge.start(session: session, user: @user)
        redirect_to user_two_factor_path, notice: "Email verified. Enter your authenticator code to finish signing in."
        return
      end

      claims = Auth::LoginClaims.for(user: @user, session: session)
      completion = complete_authenticated_session!(@user, claims: claims)

      redirect_to completion.redirect_url, allow_other_host: true
    rescue Auth::LoginClaims::Denied => e
      session.delete(:pending_email_verification_user_id)
      redirect_to login_path, alert: e.message
    end

    def resend
      Auth::EmailOtpService.issue(user: @user, purpose: Auth::EmailOtpService::PURPOSE_EMAIL_VERIFICATION)
      redirect_to verify_email_path, notice: "A new verification code has been sent."
    end

    private

    def redirect_verified_user!
      return unless user_signed_in? && current_user.email_verified?

      redirect_to root_path
    end

    def load_pending_user!
      @user = User.find_by(id: session[:pending_email_verification_user_id])
      return if @user.present? && !@user.email_verified?

      session.delete(:pending_email_verification_user_id)
      redirect_to login_path, alert: "Your verification session is no longer valid. Sign in to continue."
    end

    def handle_failed_verification(result)
      flash.now[:alert] = case result.reason
      when :expired then "That code has expired. Request a new email code."
      when :too_many_attempts then "Too many incorrect codes. Request a new email code."
      else "That verification code was not accepted."
      end

      render :show, status: :unprocessable_entity
    end

    def ensure_resend_not_rate_limited!
      user_result = Security::RateLimiter.check(key: "email-otp:resend:user:#{@user.id}", limit: 5, period: 900)
      ip_result = Security::RateLimiter.check(key: "email-otp:resend:ip:#{request.remote_ip}", limit: 10, period: 900)
      result = [user_result, ip_result].find { |entry| !entry.allowed? }
      return if result.nil?

      response.set_header("Retry-After", result.retry_after.to_s)
      redirect_to verify_email_path, alert: "Please wait before requesting another code."
    end
  end
end
