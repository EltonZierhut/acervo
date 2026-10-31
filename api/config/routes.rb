Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Núcleo
      resource :session, only: %i[create show destroy] # login, sessão atual, logout
      resources :modules, only: :index

      # Módulo: Códigos
      namespace :codes do
        resources :projects
        resources :snippets
        get "search", to: "search#index"
      end

      # Próximos módulos entram aqui, cada um no seu namespace.
    end
  end
end
