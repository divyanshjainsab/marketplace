class AuthMailer < Devise::Mailer
  default template_path: "auth_mailer"

  def email_otp
    @user = params[:user]
    @code = params[:code]
    @purpose = params[:purpose]
    @expires_in_minutes = params[:expires_in_minutes]

    mail(
      to: @user.email,
      subject: subject_for(@purpose)
    )
  end

  private

  def subject_for(purpose)
    case purpose
    when Auth::EmailOtpService::PURPOSE_EMAIL_VERIFICATION
      "Verify your email"
    when Auth::EmailOtpService::PURPOSE_TWO_FACTOR_RECOVERY
      "Your account recovery code"
    else
      "Your security code"
    end
  end
end
