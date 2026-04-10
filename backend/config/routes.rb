Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :auth do
    get "oidc/start/:app", to: "oidc_sessions#start"
    get "oidc/callback/:app", to: "oidc_sessions#callback"
    post "session/refresh", to: "oidc_sessions#refresh"
    delete "session", to: "oidc_sessions#logout"
    post "session/logout", to: "oidc_sessions#logout"
    post "sso/claims", to: "sso_claims#create"
  end

  namespace :api do
    namespace :v1 do
      namespace :admin do
        get :dashboard, to: "dashboard#show"
        resources :users, only: %i[index show]
        resources :organizations, only: %i[index show]
        resources :marketplaces, only: %i[index show]
        resources :products, only: %i[index]
        resources :listings, only: %i[index]
        resources :categories, only: %i[index]
        resources :product_types, only: %i[index]
        resource :site_editor, only: %i[show update]
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
      get :homepage, to: "homepages#show"
    end
  end
end
