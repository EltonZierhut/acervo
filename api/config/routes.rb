Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Núcleo
      resource :session, only: %i[create show destroy] # login, sessão atual, logout
      resources :modules, only: :index

      # Módulo: Códigos
      namespace :codes do
        resources :snippets
      end

      # Próximos módulos entram aqui, cada um no seu namespace.
    end
  end

  # Interface (SPA). O catch-all precisa ser a ÚLTIMA rota: qualquer navegação que aceite
  # HTML e não seja da API, do health check ou de assets recebe o index.html do React.
  root "spa#index"
  get "*path", to: "spa#index", format: false,
    constraints: ->(request) { request.format.html? && !request.path.start_with?("/api", "/up", "/assets") }
end
