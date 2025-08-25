Rails.application.routes.draw do

  scope "(:locale)", locale: /en|vi/ do
    root to: "guest#homepage"

    get "guest/homepage"

    devise_for :users,
      only: %i(sessions registrations omniauth_callbacks confirmations),
      controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

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
          resources :test_results, only: %i(show)
        end
      end
      resources :words, only: %i(index)
      resources :lessons do
        resources :user_tests, only: %i(create edit update)
      end
    end

    namespace :admin do
      resources :words

      resources :courses do
        resources :lessons
      end

      resources :tests do
        resources :questions, except: %i(show index) do
          resources :answers, only: %i(new create destroy)
        end
      end
      resources :user_courses, only: [:index] do
        member do
          patch :approve
          patch :reject
          get :reject_detail
          get :reject_form
          get :profile
        end
        collection do
          post :approve_selected
          post :reject_selected
        end
      end
    end

    namespace :api do
      namespace :v1 do
        resources :words, only: [] do
          collection do
            get :search
          end
        end

        resources :tests, only: [] do
          collection do
            get :search
          end
        end
      end
    end

  end
end
