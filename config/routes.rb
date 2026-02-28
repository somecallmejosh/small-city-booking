Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :admin do
    root to: "dashboard#index"
    resources :slots, only: [ :index, :new, :create, :destroy ] do
      collection do
        get  :bulk_new
        post :bulk_create
      end
    end
    resources :bookings, only: [ :index, :show, :new, :create ] do
      member     { post :cancel }
      collection { post :bulk_cancel }
    end
    resource :agreement, only: [ :show, :edit, :update ]
    resource :settings, only: [ :show, :edit, :update ]
    resources :customers, only: [ :index, :show, :edit, :update ]
  end

  get "/help", to: "help#show"

  resources :bookings, only: [ :index, :new, :create, :show ] do
    member { post :cancel }
  end
  resources :slot_holds, only: [ :create, :destroy ]
  resources :push_subscriptions, only: [ :create, :destroy ]
  post "/webhooks/stripe", to: "webhooks#stripe"

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root to: "home#index"
end
