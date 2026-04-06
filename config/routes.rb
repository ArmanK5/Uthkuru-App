Rails.application.routes.draw do
  root "game#show"

  post "/round",  to: "game#round"
  post "/answer", to: "game#answer"

  get "up" => "rails/health#show", as: :rails_health_check
end