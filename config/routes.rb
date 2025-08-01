Rails.application.routes.draw do
  scope "(:locale)", locale: /en|vi/ do
    root "static_pages#home"

    get "static_pages/home"
    get "static_pages/help"
    get "static_pages/contact"

    get "demo_partials/new"
    get "demo_partials/edit"

    get "signup", to: "users#new"
    post "signup", to: "users#create"

    get "/login", to: "sessions#new"
    post "/login", to: "sessions#create"
    delete "/logout", to: "sessions#destroy"

    get '/auth/:provider/callback', to: 'sessions#omniauth'
    get "/auth/failure", to: redirect("/")

    resources :users, only: %i(show)
    resources :microposts, only: %i(index)
    resources :products
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
