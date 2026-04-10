Rails.application.routes.draw do
  root "home#index"

  if Rails.env.development?
    require "letter_opener_web"
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  devise_for :users, controllers: {
    sessions: "auth/sessions",
    registrations: "auth/registrations"
  }

  devise_scope :user do
    get "/login", to: "auth/sessions#new"
    post "/login", to: "auth/sessions#create"
    delete "/logout", to: "auth/sessions#destroy"
    get "/verify-email", to: "auth/email_verifications#show", as: :verify_email
    post "/verify-email", to: "auth/email_verifications#create"
    post "/verify-email/resend", to: "auth/email_verifications#resend", as: :resend_verify_email
  end

  post "/validate_token", to: "auth/tokens#validate"
  post "/refresh_token", to: "auth/tokens#refresh"

  get "/users/otp", to: "users/two_factor#show", as: :user_two_factor
  get "/users/two_factor", to: "users/two_factor#show"
  post "/users/otp_verify", to: "users/two_factor#create", as: :user_otp_verify
  get "/users/two_factor/setup", to: "users/two_factor_setups#show", as: :two_factor_setup_page
  post "/users/two_factor/setup", to: "users/two_factor_setups#create", as: :two_factor_setup
  post "/users/two_factor/setup/verify", to: "users/two_factor_setups#verify", as: :verify_two_factor_setup
  delete "/users/two_factor/setup", to: "users/two_factor_setups#destroy"
  get "/users/two_factor/recovery", to: "users/two_factor_recoveries#show", as: :user_two_factor_recovery
  post "/users/two_factor/recovery", to: "users/two_factor_recoveries#create"
  post "/users/two_factor/recovery/verify", to: "users/two_factor_recoveries#verify", as: :verify_user_two_factor_recovery

  get "up" => "rails/health#show", as: :rails_health_check
end
