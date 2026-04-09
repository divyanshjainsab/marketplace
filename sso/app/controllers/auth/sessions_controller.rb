module Auth
  class SessionsController < Devise::SessionsController
    protect_from_forgery with: :exception

    def create
      self.resource = warden.authenticate!(auth_options)
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)

      token = Sso::JwtTokens.issue(user: resource)
      decoded = Sso::JwtTokens.decode(token: token)
      exp = Time.at(decoded.payload.fetch("exp"))

      respond_to do |format|
        format.html do
          cookies.encrypted[:sso_jwt] = {
            value: token,
            expires: exp,
            httponly: true,
            secure: Rails.env.production?,
            same_site: :lax
          }
          redirect_to after_sign_in_path_for(resource)
        end
        format.json do
          render json: {
            token: token,
            exp: decoded.payload["exp"],
            user: { external_id: resource.external_id, email: resource.email, name: resource.name }
          }
        end
      end
    end

    def destroy
      token = request_token
      revoke_token(token) if token.present?

      cookies.delete(:sso_jwt)
      sign_out(resource_name)

      respond_to do |format|
        format.html { redirect_to login_path, notice: "Logged out" }
        format.json { head :no_content }
      end
    end

    private

    def request_token
      header = request.headers["Authorization"].to_s
      return header.split.last if header.start_with?("Bearer ")

      cookies.encrypted[:sso_jwt].to_s.presence
    end

    def revoke_token(token)
      decoded = Sso::JwtTokens.decode(token: token)
      jti = decoded.payload["jti"]
      exp = Time.at(decoded.payload["exp"])
      JwtDenylist.create!(jti: jti, exp: exp)
    rescue JWT::DecodeError
      nil
    end
  end
end
