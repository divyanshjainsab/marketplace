Rails.application.routes.draw do
  root "home#index"

  devise_for :users, controllers: { sessions: "auth/sessions" }

  devise_scope :user do
    get "/login", to: "auth/sessions#new"
    post "/login", to: "auth/sessions#create"
    delete "/logout", to: "auth/sessions#destroy"
  end

  post "/validate_token", to: "auth/tokens#validate"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
