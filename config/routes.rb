Rails.application.routes.draw do
  resources :users
  root 'users#index'
  
  get 'count', to: 'api#users_count'
  get 'countries', to: 'api#countries'
  get 'cities', to: 'api#cities'
  get 'universities', to: 'api#universities'
end
