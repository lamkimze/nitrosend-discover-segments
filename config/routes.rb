Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "health", to: "health#show"

  root "audiences#index"

  resource :audience, only: :show, controller: "audiences" do
    post :analyse
  end
  resources :analyses, only: :show
  resources :segments, only: :show do
    member do
      post :archive
    end
    resources :memberships, only: :destroy, controller: "segment_memberships"
    resources :campaigns, only: %i[new create]
  end
  resources :campaigns, only: %i[show update]

  namespace :api do
    namespace :v1 do
      namespace :audience do
        resources :analyses, only: %i[create show], controller: "/api/v1/audience/analyses"
      end
      resources :segments, only: %i[index show], controller: "/api/v1/segments" do
        member do
          get :contacts
        end
      end
    end
  end
end
