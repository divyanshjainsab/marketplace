module Users
  class TwoFactorRecoveriesController < ApplicationController
    before_action :redirect_authenticated_user!
    before_action :load_pending_user!
    before_action :ensure_recovery_resend_not_rate_limited!, only: :create

    def show
    end

    def create
      Auth::EmailOtpService.issue(user: @user, purpose: Auth::EmailOtpService::PURPOSE_TWO_FACTOR_RECOVERY)
      session[:two_factor_recovery_user_id] = @user.id
      redirect_to user_two_factor_recovery_path, notice: "We sent a recovery code to #{@user.email}."
    end

    def verify
      result = Auth::EmailOtpService.verify(
        user: @user,
        purpose: Auth::EmailOtpService::PURPOSE_TWO_FACTOR_RECOVERY,
        code: params[:otp_attempt]
      )

      unless result.ok?
        flash.now[:alert] = case result.reason
        when :expired then "That recovery code has expired. Request a new one."
        when :too_many_attempts then "Too many incorrect codes. Start recovery again."
        else "That recovery code was not accepted."
        end
        return render :show, status: :unprocessable_entity
      end

      @user.update!(otp_required_for_login: false, otp_backup_codes: [], otp_secret: nil)
      session.delete(:two_factor_recovery_user_id)
      Auth::OtpChallenge.clear(session: session)
      completion = complete_authenticated_session!(@user)
      redirect_to completion.redirect_url, allow_other_host: true
    end

    private

    def redirect_authenticated_user!
      return unless user_signed_in?

      redirect_to root_path
    end

    def load_pending_user!
      challenge = Auth::OtpChallenge.fetch(session: session)
      @user = User.find_by(id: session[:two_factor_recovery_user_id] || challenge&.user_id)
      return if @user.present?

      redirect_to login_path, alert: "Start sign-in again to use account recovery."
    end

    def ensure_recovery_resend_not_rate_limited!
      ip_result = Security::RateLimiter.check(key: "recovery:ip:#{request.remote_ip}", limit: 5, period: 900)
      user_result = Security::RateLimiter.check(key: "recovery:user:#{@user.id}", limit: 3, period: 900)
      result = [ip_result, user_result].find { |entry| !entry.allowed? }
      return if result.nil?

      response.set_header("Retry-After", result.retry_after.to_s)
      redirect_to user_two_factor_recovery_path, alert: "Please wait before requesting another recovery code."
    end
  end
end
