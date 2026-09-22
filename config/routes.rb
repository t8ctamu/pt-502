Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "home/index"
  root "home#index"

  devise_for :members, controllers: { omniauth_callbacks: "members/omniauth_callbacks" }
  devise_scope :member do
    get "members/sign_in",  to: "members/sessions#new",     as: :new_member_session
    get "members/sign_out", to: "members/sessions#destroy", as: :destroy_member_session
  end

  resources :members, only: [ :index, :update ]
  resource  :profile, only: [ :edit, :update ]

  resources :events do
    member do
      get :ics
    end
  end
end
