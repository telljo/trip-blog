Rails.application.routes.draw do
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get  "sign_in", to: "sessions#new"
  post "sign_in", to: "sessions#create"
  get  "sign_up", to: "registrations#new"
  post "sign_up", to: "registrations#create"
  resources :sessions, only: [ :index, :show, :destroy ]
  resource  :password, only: [ :edit, :update ]
  namespace :identity do
    resource :email,              only: [ :edit, :update ]
    resource :email_verification, only: [ :show, :create ]
    resource :password_reset,     only: [ :new, :edit, :create, :update ]
  end
  root "pages#home"
  resources :trips do
    resources :posts do
      member do
        delete :remove_attachment
      end
    end
    resources :trip_followers, only: [ :create, :destroy ]
    resources :trip_companions
  end
  resources :posts do
    resources :user_post_likes, only: [ :create, :destroy ]
    resources :post_comments, only: [ :create, :edit, :update ]
    resources :post_attachment_captions, only: [ :create, :edit, :update ] do
      member do
        delete :remove_attachment_caption
      end
    end
  end
  resources :post_comment_replies, only: [ :destroy ]
  resources :post_attachment_captions, only: [ :destroy ]
  resources :post_comments, only: [ :edit, :update, :destroy ] do
    resources :post_comment_replies, only: [ :create, :edit, :update, :destroy ]
    resources :post_comment_likes, only: [ :create, :destroy ]
  end
  resources :users, param: :username, constraints: { username: /[^\/]+/ }, defaults: { format: nil }
  resource :session
  resources :passwords, param: :token
  resources :geolocations do
    collection do
      get :search
      post :find_location
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
