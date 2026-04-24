Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Storefront convenience routes (no tenant identifiers; tenant resolved from request host/port).
  get "listings", to: "api/v1/listings#index"

  namespace :auth do
    get "oidc/start/:app", to: "oidc_sessions#start"
    get "oidc/callback/:app", to: "oidc_sessions#callback"
    post "session/refresh", to: "oidc_sessions#refresh"
    delete "session", to: "oidc_sessions#logout"
    post "session/logout", to: "oidc_sessions#logout"
  end

  namespace :api do
    get "listings", to: "v1/listings#index"
    get "cart", to: "v1/carts#show"
    post "cart/items", to: "v1/cart_items#create"
    patch "cart/items/:variant_id", to: "v1/cart_items#update"
    delete "cart/items/:variant_id", to: "v1/cart_items#destroy"
    resource :market_place_options, only: %i[update]
    resource :market_places, only: %i[update]
    resources :assets, only: %i[index destroy]
    resources :landing_components, only: %i[show]

    namespace :v1 do
      namespace :admin do
        get :dashboard, to: "dashboard#show"
        resources :users, only: %i[index show]
        resources :organizations, only: %i[index show]
        resources :marketplaces, only: %i[index show]
        resources :products, only: %i[index]
        resources :listings, only: %i[index create update destroy]
        resources :categories, only: %i[index create]
        resources :product_types, only: %i[index create]
        resources :media_assets, only: %i[create]
        resource :site_editor, only: %i[show update]
        resource :settings, only: %i[show update]
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
      resource :cart, only: %i[show]
      resources :cart_items, only: %i[create update destroy], param: :variant_id
      get :session, to: "sessions#show"
      get :me, to: "sessions#show"
      get :homepage, to: "homepages#show"
    end

    namespace :v2 do
      resources :pages, except: %i[create update destroy show] do
        collection do
          get "/:slug/components", to: "pages#show"
          put "/:slug/components", to: "landing_components#batch_update"
          get "/:slug/assets", to: "assets#index"
          post "/:slug/assets", to: "assets#create"
          get "/:slug/assets/:id", to: "assets#show"
          get "/:slug/versions", to: "page_versions#index"
          post "/:slug/versions/:id/restore", to: "page_versions#restore"
        end
      end

      resources :landing_components, only: %i[update]
    end
  end
end
