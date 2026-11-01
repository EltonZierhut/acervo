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

      # Módulo: Iniciativas. Marcos e tarefas são criados e listados dentro da iniciativa e
      # alterados pelo próprio id (/initiatives/tasks/:id).
      namespace :initiatives do
        resources :contexts, only: %i[index create update destroy]
        resources :initiatives, shallow: true do
          post :verify_repository, on: :member
          resources :milestones, only: %i[index create update destroy]
          resources :tasks, only: %i[index create update destroy] do
            resources :task_images, only: %i[index create show destroy]
            resources :task_links, only: %i[index create update destroy]
            resources :runs, only: %i[index create]
          end
        end
        # Fila de execuções de todas as iniciativas.
        resources :runs, only: :index do
          post :cancel, on: :member
          resources :answers, only: :create, controller: "run_answers"
        end
        get "executor_status", to: "executor_status#show"

        # Programa executor: autentica por token, não por sessão (spec 006, FR-023).
        namespace :executor do
          post "claim", to: "claims#create"
          get "images/:id", to: "images#show"
          post "runs/:id/heartbeat", to: "runs#heartbeat"
          post "runs/:id/questions", to: "runs#questions"
          post "runs/:id/complete", to: "runs#complete"
          get "repository_checks", to: "repository_checks#index"
          post "repository_checks", to: "repository_checks#create"
        end
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
