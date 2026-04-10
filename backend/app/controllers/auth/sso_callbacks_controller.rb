require "uri"

module Auth
  class SsoCallbacksController < ActionController::API
    def show
      token = params[:token].to_s
      refresh_token = params[:refresh_token].to_s
      exp = params[:exp].to_s
      refresh_exp = params[:refresh_exp].to_s
      app = params[:app].to_s
      return_to = sanitize_return_to(params[:return_to] || params[:redirect])

      if token.blank? || refresh_token.blank?
        return redirect_to frontend_login_url(app: app, return_to: return_to), allow_other_host: true
      end

      validation = Sso::TokenValidator.call(token: token)
      unless validation.valid
        return redirect_to frontend_login_url(app: app, return_to: return_to), allow_other_host: true
      end

      sync_user!(validation)

      redirect_to frontend_callback_url(
        app: app,
        token: token,
        refresh_token: refresh_token,
        exp: exp,
        refresh_exp: refresh_exp,
        return_to: return_to
      ), allow_other_host: true
    end

    private

    def sync_user!(validation)
      external_id = validation.external_id.to_s
      return if external_id.blank?

      user = User.kept.find_or_initialize_by(external_id: external_id)
      if user.respond_to?(:sso_user_id=) && validation.respond_to?(:sso_user_id) && validation.sso_user_id.present?
        user.sso_user_id = validation.sso_user_id
      end
      user.email = validation.email if validation.email.present?
      user.name = validation.name if validation.name.present?
      if user.respond_to?(:roles=) && validation.respond_to?(:roles) && validation.roles.is_a?(Array)
        user.roles = validation.roles
      end
      user.save! if user.changed?
    end

    def frontend_login_url(app:, return_to:)
      base = frontend_base_url(app)
      uri = URI.parse(base)
      uri.path = "/login"
      uri.query = { return_to: return_to }.compact.to_query
      uri.to_s
    rescue URI::InvalidURIError
      "/"
    end

    def frontend_callback_url(app:, token:, refresh_token:, exp:, refresh_exp:, return_to:)
      base = frontend_base_url(app)
      uri = URI.parse(base)
      uri.path = "/callback"
      uri.query = {
        token: token,
        refresh_token: refresh_token,
        exp: exp.presence,
        refresh_exp: refresh_exp.presence,
        return_to: return_to
      }.compact.to_query
      uri.to_s
    rescue URI::InvalidURIError
      "/"
    end

    def frontend_base_url(app)
      case app.to_s
      when "admin"
        ENV.fetch("ADMINFRONT_BASE_URL", "http://localhost:3004")
      else
        ENV.fetch("CLIENTFRONT_BASE_URL", "http://localhost:3000")
      end
    end

    def sanitize_return_to(raw)
      value = raw.to_s.strip
      return nil if value.blank?
      return nil unless value.start_with?("/")
      return nil if value.start_with?("//")

      value
    end
  end
end
