Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "help", to: "help#index"
  get "help/member", to: "help#member", as: :member_help
  get "help/officer", to: "help#officer", as: :officer_help
  get "help/system", to: "help#system", as: :system_help

  get "home/index"
  root "home#index"

  devise_for :members, controllers: { omniauth_callbacks: "members/omniauth_callbacks" }
  devise_scope :member do
    get "members/sign_in",  to: "members/sessions#new",     as: :new_member_session
    get "members/sign_out", to: "members/sessions#destroy", as: :destroy_member_session
  end

  resources :members, only: [ :index, :edit, :update ] do
    member do
      patch :change_role
      patch :set_points
      patch :remove
      patch :restore
    end
  end

  resources :semesters, only: [ :index, :show ] do
    collection do
      post :reset
    end
  end

  resource :profile, only: [ :edit, :update ]
  resource :point_settings, only: %i[show update] do
    post :add_type
    delete "types/:id", to: "point_settings#destroy_type", as: :destroy_type
  end

  resources :events do
    resource :check_in, only: [ :show, :create ], controller: "event_check_ins"
    member do
      get :ics
      get :check_in_qr
    end
  end

  resources :event_submissions, only: %i[new create]

  resources :submission_reviews, only: :index do
    member do
      patch :approve
      patch :deny
    end
  end
end
