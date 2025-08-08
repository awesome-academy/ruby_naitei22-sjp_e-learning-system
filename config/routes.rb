Rails.application.routes.draw do
  scope "(:locale)", locale: /en|vi/ do
    root to: "guest#homepage"

    get "guest/homepage"
    get "signup", to: "users#new"
    post "signup", to: "users#create"

    get "/login", to: "sessions#new"
    post "/login", to: "sessions#create"
    delete "/logout", to: "sessions#destroy"

    get "/auth/:provider/callback", to: "sessions#omniauth"
    get "/auth/failure", to: redirect("/")

    resources :users, only: %i(show edit update)

    namespace :user do
      resources :courses, only: %i(index show) do
        member do
          post :enroll
          patch :start
        end

        resources :lessons, only: %i(show) do
          member do
            get :study
            get :test_history
          end
        end
      end
      resources :words, only: %i(index)
      resources :lessons do
        resources :user_tests, only: %i(create edit update)
      end
    end

    namespace :admin do
      resources :words
      resources :courses
      resources :lessons
      resources :tests do
        resources :questions, except: %i(show index) do
          resources :answers, only: %i(new create destroy)
        end
      end
    end
  end
end
