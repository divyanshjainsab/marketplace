class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :layout_container_class

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[name])
  end

  def layout_container_class
    path = request.path.to_s

    # Auth-like views are narrow cards; keep flash and layout aligned with them.
    if path.start_with?(
      "/login",
      "/users/sign_in",
      "/users/sign_up",
      "/users/password",
      "/users/unlock",
      "/users/confirmation",
      "/verify-email",
      "/users/otp",
      "/users/two_factor",
      "/users/two_factor/setup",
      "/users/two_factor/recovery"
    )
      return "mx-auto w-full max-w-md"
    end

    # Profile pages are slightly wider.
    if path.start_with?("/profile", "/addresses")
      return "mx-auto w-full max-w-3xl"
    end

    "mx-auto w-full max-w-5xl"
  end

  def complete_authenticated_session!(user, claims: {})
    sign_in(:user, user)
    session.delete(:pending_login_claims)

    oidc_request = session.delete(:oidc_authorization_request)
    if oidc_request.is_a?(Hash)
      resolved_claims = claims
      if resolved_claims.blank?
        resolved_claims = Auth::LoginClaims.for(user: user, session: session)
      end
      return Oidc::AuthorizationCompletion.call(
        user: user,
        request: request,
        session_request: oidc_request,
        claims: resolved_claims
      )
    end

    Oidc::AuthorizationCompletion::Result.new(redirect_url: root_path)
  end
end
