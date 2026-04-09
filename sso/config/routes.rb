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
  end

  post "/validate_token", to: "auth/tokens#validate"
  post "/refresh_token", to: "auth/tokens#refresh"

  get "up" => "rails/health#show", as: :rails_health_check
end
