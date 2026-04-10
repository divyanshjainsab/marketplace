module Users
  class TwoFactorController < ApplicationController
    protect_from_forgery with: :exception, unless: -> { request.format.json? }
    before_action :redirect_authenticated_user!, only: %i[show create]
    before_action :load_challenge!
    before_action :ensure_otp_not_rate_limited!, only: :create

    def show
      self.resource = current_otp_user
    end

    def create
      otp_attempt = normalized_otp_attempt

      unless otp_attempt.present?
        return render_invalid_otp!("Enter the 6-digit code from your authenticator app.")
      end

      if Auth::TotpService.verify_login(user: current_otp_user, code: otp_attempt)
        begin
          claims = Auth::LoginClaims.for(user: current_otp_user, session: session)
          completion = complete_authenticated_session!(current_otp_user, claims: claims)
          Auth::OtpChallenge.clear(session: session)
          redirect_to completion.redirect_url, allow_other_host: true
          return
        rescue Auth::LoginClaims::Denied => e
          Auth::OtpChallenge.clear(session: session)
          redirect_to login_path, alert: e.message
          return
        end
      end

      incremented = Auth::OtpChallenge.increment_attempts(session: session)
      if incremented&.attempts.to_i >= Auth::OtpChallenge::MAX_ATTEMPTS
        Auth::OtpChallenge.clear(session: session)
        return handle_stale_challenge!("Too many incorrect codes. Please sign in again.")
      end

      render_invalid_otp!("That code was not accepted. Try the latest code from your authenticator app.")
    end

    private

    attr_writer :resource

    def resource
      @resource
    end
    helper_method :resource

    def resource_name
      :user
    end
    helper_method :resource_name

    def redirect_authenticated_user!
      return unless user_signed_in?

      Auth::OtpChallenge.clear(session: session)
      redirect_to root_path
    end

    def load_challenge!
      @challenge = Auth::OtpChallenge.fetch(session: session)
      return handle_stale_challenge!("Your verification session has expired. Please sign in again.") if @challenge.nil?
      return handle_stale_challenge!("Your verification session has expired. Please sign in again.") if @challenge.expired?

      @current_otp_user = User.find_by(id: @challenge.user_id)
      return handle_stale_challenge!("Your verification session is no longer valid. Please sign in again.") if @current_otp_user.nil?
    end

    def current_otp_user
      @current_otp_user
    end

    def normalized_otp_attempt
      direct = params[:otp_attempt].to_s
      digits = Array(params[:otp_digits]).join
      (direct.presence || digits).to_s.gsub(/\D/, "")
    end

    def render_invalid_otp!(message)
      self.resource = current_otp_user
      flash.now[:alert] = message
      render :show, status: :unprocessable_entity
    end

    def handle_stale_challenge!(message)
      Auth::OtpChallenge.clear(session: session)
      redirect_to login_path, alert: message
    end

    def ensure_otp_not_rate_limited!
      ip_result = Security::RateLimiter.check(key: "otp:ip:#{request.remote_ip}", limit: 20, period: 300)
      user_result = Security::RateLimiter.check(key: "otp:user:#{@challenge.user_id}", limit: 10, period: 300)
      result = [ip_result, user_result].find { |entry| !entry.allowed? }
      return if result.nil?

      response.set_header("Retry-After", result.retry_after.to_s)
      self.resource = current_otp_user
      flash.now[:alert] = "Too many code attempts. Wait a moment and try again."
      render :show, status: :too_many_requests
    end
  end
end
