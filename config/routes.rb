Rails.application.routes.draw do
  scope "(:locale)", locale: /en|vi/ do
    get "guest/homepage"
    get "signup", to: "users#new"
    post "signup", to: "users#create"

    get "/login", to: "sessions#new"
    post "/login", to: "sessions#create"
    delete "/logout", to: "sessions#destroy"

    get "/auth/:provider/callback", to: "sessions#omniauth"
    get "/auth/failure", to: redirect("/")

    namespace :user do
      resources :courses, only: %i(index show) do
        member do
          post :enroll
          patch :start
        end

        resources :lessons, only: %i(show) do
          member do
            get :study
            get :test
            get :test_history
          end
        end
      end
      resources :words, only: %i(index)
    end
    root to: "guest#homepage"

    namespace :admin do
      resources :words
      resources :courses
      resources :lessons
      resources :tests
    end
  end
end
