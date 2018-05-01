Rails.application.routes.draw do
    root "sessions#new"

    get "/login", to: "sessions#new"
    post "/login", to: "sessions#create"
    delete "/logout",  to: "sessions#destroy"

    resources :users, only: %i(show edit update) do
        get "tournaments/refresh", to: "tournaments#refresh_all"

        resources :tournaments, only: %i(index show edit update) do
            get "refresh", on: :member

            resources :matches , only: %i(update) do
                post "switch", on: :member
                post "start", on: :member
            end
        end
    end

    get "view/:id", to: "tournament_viewer#view", as: :view_tournament
    get "view/:id/gold", to: "tournament_viewer#gold", as: :view_tournament_gold
    get "view/:id/blue", to: "tournament_viewer#blue", as: :view_tournament_blue
    get "view/:id/gold_score", to: "tournament_viewer#gold_score", as: :view_tournament_gold_score
    get "view/:id/blue_score", to: "tournament_viewer#blue_score", as: :view_tournament_blue_score

    get "/routes", to: redirect("/rails/info/routes") if Rails.env.development?
end
