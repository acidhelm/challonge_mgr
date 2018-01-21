Rails.application.routes.draw do
    root "users#index"
    resources :users do
        get "tournaments/refresh", to: "tournaments#refresh_all"

        resources :tournaments, only: [ :index, :show, :edit, :update ] do
            get "refresh", on: :member

            resources :matches , only: [ :update ] do
                post "switch", on: :member
                post "start", on: :member
            end
        end
    end
    get "view/:id", to: "tournaments#view"
    get "view/:id/gold", to: "tournaments#gold"
    get "view/:id/blue", to: "tournaments#blue"
end
