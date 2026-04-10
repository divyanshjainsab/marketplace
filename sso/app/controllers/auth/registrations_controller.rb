module Auth
  class RegistrationsController < Devise::RegistrationsController
    before_action :redirect_signed_in_user!, only: %i[new create]
    before_action :ensure_signup_not_rate_limited!, only: :create

    def new
      build_resource({})
    end

    def create
      build_resource(sign_up_params)
      resource.email_verified = false
      resource.otp_required_for_login = false if resource.otp_required_for_login.nil?

      if resource.save
        expire_data_after_sign_in!
        sign_out(resource_name) if user_signed_in?
        session[:pending_email_verification_user_id] = resource.id
        Auth::EmailOtpService.issue(user: resource, purpose: Auth::EmailOtpService::PURPOSE_EMAIL_VERIFICATION)
        redirect_to verify_email_path, notice: "Verify your email to finish creating your account."
        return
      end

      clean_up_passwords resource
      set_minimum_password_length
      render :new, status: :unprocessable_entity
    end

    private

    def redirect_signed_in_user!
      return unless user_signed_in?

      redirect_to root_path
    end

    def ensure_signup_not_rate_limited!
      email = sign_up_params[:email].to_s.downcase
      ip_result = Security::RateLimiter.check(key: "signup:ip:#{request.remote_ip}", limit: 10, period: 300)
      email_result = Security::RateLimiter.check(key: "signup:email:#{email}", limit: 3, period: 900)
      result = [ip_result, email_result].find { |entry| !entry.allowed? }
      return if result.nil?

      response.set_header("Retry-After", result.retry_after.to_s)
      build_resource(sign_up_params.except(:password, :password_confirmation))
      resource.errors.add(:base, "Too many sign-up attempts. Please wait and try again.")
      render :new, status: :too_many_requests
    end
  end
end
