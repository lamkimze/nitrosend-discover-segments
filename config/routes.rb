Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "segments#index"

  resources :discoveries, only: %i[create show]
  resources :segments, only: %i[index show update] do
    member do
      post :accept
      post :dismiss
    end
  end

  resource :demo_reset, only: :create, controller: "demo_resets"
end
