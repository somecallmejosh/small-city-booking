Rails.application.routes.draw do
  resource  :session
  resources :passwords,           param: :token
  resource  :registration,        only: [ :new, :create ]
  resources :email_verifications, only: [ :new, :create, :show ], param: :token
  resource  :profile,             only: [ :edit, :update ]

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :admin do
    root to: "dashboard#index"
    resources :slots, only: [ :index, :new, :create, :destroy ] do
      collection do
        get    :bulk_new
        post   :bulk_create
        delete :bulk_destroy
      end
    end
    resources :bookings, only: [ :index, :show, :new, :create ] do
      member     { post :cancel }
      collection { post :bulk_cancel }
    end
    resource :agreement, only: [ :show, :edit, :update ]
    resource :settings, only: [ :show, :edit, :update ]
    resources :customers, only: [ :index, :show, :new, :create, :edit, :update ]
    get "docs",            to: "docs#index",     as: :docs
    get "docs/slots",      to: "docs#slots",     as: :docs_slots
    get "docs/bookings",   to: "docs#bookings",  as: :docs_bookings
    get "docs/customers",  to: "docs#customers", as: :docs_customers
    get "docs/agreement",  to: "docs#agreement", as: :docs_agreement
    get "docs/settings",   to: "docs#settings",  as: :docs_settings
    get "docs/tips",       to: "docs#tips",      as: :docs_tips
  end

  get "/help",                 to: "help#index",          as: :help
  get "/help/getting-started", to: "help#getting_started", as: :help_getting_started
  get "/help/calendar",        to: "help#calendar",        as: :help_calendar
  get "/help/checkout",        to: "help#checkout",        as: :help_checkout
  get "/help/cancellations",   to: "help#cancellations",   as: :help_cancellations
  get "/help/notifications",   to: "help#notifications",   as: :help_notifications
  get "/help/account",         to: "help#account",         as: :help_account
  get "/help/terms",           to: "help#terms",           as: :help_terms

  resources :bookings, only: [ :index, :new, :create, :show ] do
    member { post :cancel }
  end
  resources :slot_holds, only: [ :create, :destroy ]
  resources :push_subscriptions, only: [ :create, :destroy ]
  post "/webhooks/stripe", to: "webhooks#stripe"

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  match "/404", to: "errors#not_found",            via: :all
  match "/422", to: "errors#unprocessable",          via: :all
  match "/500", to: "errors#internal_server_error",  via: :all

  root to: "admin/dashboard#index", as: nil, constraints: lambda { |req|
    session_id = req.cookie_jar.signed[:session_id]
    session_id && Session.find_by(id: session_id)&.user&.admin?
  }
  root to: "home#index"
end
