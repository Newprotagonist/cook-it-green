Rails.application.routes.draw do
  root "weeks#index"

  resources :weeks, only: %i[index show], param: :number
  resources :dishes, only: :show, param: :key

  resource :profile, only: %i[show update]
  resources :nutrition_targets, path: "cibles", only: %i[index create update] do
    member do
      post :activate
      post :recalculate
    end
    collection { post :from_profile }
  end

  resource :push_subscription, only: %i[create destroy]

  # Sonde de santé de Kamal. Elle est interrogée en HTTP simple depuis le réseau
  # Docker privé : voir les exclusions dans config/environments/production.rb.
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA — ces contrôleurs n'héritent pas d'ApplicationController et restent
  # donc accessibles sans Basic Auth, ce qu'exigent le navigateur et l'OS.
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
