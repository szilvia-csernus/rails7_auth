Rails.application.routes.draw do
  get 'static_pages/home'
  root "static_pages#home"
  post "sign_up", to: "users#create"
  get "sign_up", to: "users#new"

  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "login", to: "sessions#new"

  resources :confirmations, only: [:create, :edit, :new], param: :confirmation_token

  # param is a named route parameter so that we can identify users by their password_reset_token
  # and not id. This is similar to what we do with the confirmations routes so we ensure that
  # a user cannot be identified by their ID.
  resources :passwords, only: [:create, :edit, :new, :update], param: :password_reset_token

  put "account", to: "users#update"
  get "account", to: "users#edit"
  delete "account", to: "users#destroy"

  resources :active_sessions, only: [:destroy] do
    collection do
      delete "destroy_all"
    end
  end
  
end
