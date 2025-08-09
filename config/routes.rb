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
    end

    namespace :admin do
      resources :words
      resources :courses
      resources :lessons
      resources :tests

      resources :tests do
        resources :questions, except: %i(show index) do
          resources :answers, only: %i(new create destroy)
        end
        get 'questions/new', on: :member, to: 'questions#new', as: 'new_question'
      end
    end
  end
end
