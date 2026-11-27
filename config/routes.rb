Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Public inventory (customers) and staff car management
  root "cars#index"
  resources :cars, only: %i[index show] do
    resource :favorite, only: %i[create destroy]
  end
  get "favorites", to: "favorites#index"

  get "share/:token", to: "shares#show", as: :share

  namespace :manage do
    resources :cars do
      resource :share, only: :create
    end

    # Sales report (spec 004). Staff only.
    resources :sales, only: :index

    # Favorite popularity ranking (spec 006). Staff only.
    get "popularity", to: "popularity#index"

    # Cars in transit (spec 003). Staff only; every action requires sign-in.
    resources :transits, only: %i[index new create show] do
      member do
        post :arrive
        post :cancel
        patch :expected_arrival
        patch :pre_sell
      end
    end
  end
end
