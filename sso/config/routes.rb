Rails.application.routes.draw do
  root "home#index"

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

  # OAuth2/OIDC Authorization Code + PKCE flow (SSO as Authorization Server)
  get "/authorize", to: "oidc/authorizations#new"
  post "/token", to: "oidc/tokens#create"
  get "/jwks.json", to: "oidc/jwks#show"

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

  get "/profile", to: "users/profiles#show", as: :profile
  patch "/profile", to: "users/profiles#update"
  get "/addresses", to: "users/addresses#index", as: :addresses
  get "/addresses/new", to: "users/addresses#new", as: :new_address
  post "/addresses", to: "users/addresses#create"
  get "/addresses/:id/edit", to: "users/addresses#edit", as: :edit_address
  patch "/addresses/:id", to: "users/addresses#update", as: :address
  delete "/addresses/:id", to: "users/addresses#destroy"

  namespace :api do
    namespace :v1 do
      match "/*path", to: "preflight#options", via: :options

      resource :profile, controller: "profile", only: %i[show update]
      resources :addresses, only: %i[index create update destroy]
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
