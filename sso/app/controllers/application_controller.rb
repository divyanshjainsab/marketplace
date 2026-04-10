class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: %i[redirect_url redirect_uri state return_to org_slug])
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[name])
  end

  def current_redirect_target
    Auth::ReturnTo.fetch(session: session)
  end

  def store_redirect_target!
    Auth::ReturnTo.store(
      session: session,
      redirect_url: params[:redirect_uri].presence || params.dig(:user, :redirect_uri).presence || params[:redirect_url].presence || params.dig(:user, :redirect_url).presence,
      state: params[:state].presence || params.dig(:user, :state).presence,
      return_to: params[:return_to].presence || params.dig(:user, :return_to).presence
    )

    org_slug = params[:org_slug].presence || params.dig(:user, :org_slug).presence
    if org_slug.present?
      session[:login_org_slug] = org_slug.to_s
    else
      session.delete(:login_org_slug)
    end
  end

  def clear_redirect_target!
    Auth::ReturnTo.clear(session: session)
  end

  def complete_authenticated_session!(user, claims: {})
    completion = Auth::SessionCompletion.call(
      user: user,
      request: request,
      redirect_target: current_redirect_target,
      fallback: root_path,
      claims: claims
    )

    sign_in(:user, user)
    set_sso_cookie(completion.token_pair)
    clear_redirect_target!
    session.delete(:pending_login_claims)
    session.delete(:login_org_slug)
    completion
  end

  def set_sso_cookie(token_pair)
    cookies.encrypted[:sso_jwt] = {
      value: token_pair.access_token,
      expires: token_pair.access_exp,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax
    }
  end
end
