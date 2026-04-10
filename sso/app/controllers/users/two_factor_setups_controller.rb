module Users
  class TwoFactorSetupsController < ApplicationController
    before_action :authenticate_user!

    def show
      if current_user.otp_required_for_login?
        session.delete(:pending_totp_secret)
        return
      end

      secret = session[:pending_totp_secret].presence || current_user.class.generate_otp_secret
      session[:pending_totp_secret] = secret
      @totp_setup = Auth::TotpService.setup_for(user: current_user, secret: secret)
    end

    def create
      setup = Auth::TotpService.setup_for(user: current_user)
      session[:pending_totp_secret] = setup.secret
      redirect_to two_factor_setup_page_path
    end

    def verify
      secret = session[:pending_totp_secret].to_s
      if Auth::TotpService.enable_for(user: current_user, secret: secret, code: params[:otp_attempt])
        session.delete(:pending_totp_secret)
        redirect_to root_path, notice: "2FA enabled successfully"
      else
        redirect_to two_factor_setup_page_path, alert: "That code was not accepted."
      end
    end

    def destroy
      current_user.update!(otp_required_for_login: false, otp_backup_codes: [], otp_secret: nil)
      session.delete(:pending_totp_secret)
      redirect_to root_path, notice: "2FA disabled"
    end
  end
end
