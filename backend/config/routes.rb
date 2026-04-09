Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
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
