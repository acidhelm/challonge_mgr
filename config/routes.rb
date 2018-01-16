Rails.application.routes.draw do
    root "users#index"
    resources :users do
        get "tournaments/refresh", to: "tournaments#refresh_all"

        resources :tournaments, only: [ :index, :show ] do
            get "refresh", on: :member
            post "switch", on: :member

            resources :matches , only: [ :update ] do
                post "switch", on: :member
                post "start", on: :member
            end
        end
    end
end
