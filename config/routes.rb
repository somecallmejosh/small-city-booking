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
    resource :agreement, only: [ :show, :edit, :update ]
    resource :settings, only: [ :show, :edit, :update ]
  end

  root to: "home#index"
end
