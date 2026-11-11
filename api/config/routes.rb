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

      # Módulo: Brag document
      namespace :brag do
        resources :entries
      end

      # Módulo: Iniciativas. Marcos e tarefas são criados e listados dentro da iniciativa e
      # alterados pelo próprio id (/initiatives/tasks/:id).
      namespace :initiatives do
        resources :contexts, only: %i[index create update destroy]
        resources :initiatives, shallow: true do
          post :verify_repository, on: :member
          resources :milestones, only: %i[index create update destroy]
          resources :tasks, only: %i[index create update destroy] do
            patch :move, on: :member
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

      # Módulo: Flashcards. Notas são criadas e listadas dentro do baralho e alteradas pelo próprio id.
      namespace :flashcards do
        resources :decks do
          resources :notes, shallow: true, only: %i[index create show update destroy] do
            post :reset, on: :member
          end
        end
        get "decks/:deck_id/study", to: "study#show", as: :deck_study
        post "cards/:id/review", to: "study#review", as: :card_review
      end

      # Módulo: Mentoria. Os itens são criados e listados dentro da mentoria e alterados pelo próprio id.
      namespace :mentoring do
        resources :mentorships, shallow: true do
          get :overview, on: :member
          resources :questions, only: %i[index create update destroy] do
            post :move, on: :member
          end
          resources :goals, only: %i[index create update destroy]
          resources :meetings, only: %i[index create show update destroy]
          resources :action_items, only: %i[index create update destroy]
          resources :competencies, only: %i[index create update destroy]
        end
        get "mentorships/:mentorship_id/assessments", to: "assessments#show", as: :mentorship_assessments
        post "mentorships/:mentorship_id/assessments", to: "assessments#create"
        delete "mentorships/:mentorship_id/assessments/:rated_on", to: "assessments#destroy", as: :mentorship_assessment
      end

      # Próximos módulos entram aqui, cada um no seu namespace.
    end
  end

  # App instalável (PWA): ficam na raiz, não em /assets. Antes do catch-all.
  get "sw.js", to: "pwa#service_worker", format: false
  get "manifest.webmanifest", to: "pwa#manifest", format: false
  get "icons/:name", to: "pwa#icon", format: false, constraints: { name: /[\w-]+\.png/ }

  # Interface (SPA). O catch-all precisa ser a ÚLTIMA rota: qualquer navegação que aceite
  # HTML e não seja da API, do health check ou de assets recebe o index.html do React.
  root "spa#index"
  get "*path", to: "spa#index", format: false,
    constraints: ->(request) { request.format.html? && !request.path.start_with?("/api", "/up", "/assets") }
end
