Rails.application.routes.draw do
    root "users#index"
    resources :users
    get "tournaments", to: "tournaments#index", as: :tournament_index
    get "tournaments/:id", to: "tournaments#show", as: :tournament
    post "tournaments/:id/start", to: "tournaments#start_match", as: :tournament_start_match
# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
