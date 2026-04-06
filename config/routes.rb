Rails.application.routes.draw do
  root "game#show"
  post '/transcribe', to: 'transcribe#create'
  get "up" => "rails/health#show", as: :rails_health_check
end