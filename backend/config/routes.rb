Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :auth do
    get "sso/callback", to: "sso_callbacks#show"
    post "sso/claims", to: "sso_claims#create"
  end

  namespace :api do
    namespace :v1 do
      namespace :admin do
        resources :users, only: %i[index show]
        resources :organizations, only: %i[index show]
        resources :marketplaces, only: %i[index show]
        get :context, to: "context#show"
      end

      resources :product_types
      resources :categories
      resources :products do
        collection do
          get :suggestions
        end
      end
      resources :variants
      resources :listings
      get :session, to: "sessions#show"
    end
  end
end
