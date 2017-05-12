Rails.application.routes.draw do
  resources :users
  get 'count', to: 'users#count'

  root 'users#index'
end
