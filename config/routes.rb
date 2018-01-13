Rails.application.routes.draw do
    root "users#index"
    resources :users
    get "tournaments", to: "tournaments#index", as: :tournament_index
    get "tournaments/:id", to: "tournaments#show", as: :tournament
    post "tournaments/:id/switch", to: "tournaments#switch_sides", as: :tournament_switch_sides
    post "tournaments/:id/start", to: "tournaments#start_match", as: :tournament_start_match
    post "tournaments/:id/score", to: "tournaments#update_score", as: :tournament_update_score
    post "tournaments/:id/winner", to: "tournaments#update_winner", as: :tournament_update_winner
# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
