module Api
  module V1
    module Initiatives
      class RunsController < ApplicationController
        include RunSerialization

        INCLUDES = [ :questions, { task: :initiative } ].freeze

        # GET .../tasks/:task_id/runs (histórico) ou GET .../runs?status=&q=&page= (fila)
        def index
          ::Initiatives::Run.expire_stale!
          return render_history if params[:task_id].present?

          scope = ::Initiatives::Run.includes(*INCLUDES).for_queue
          scope = scope.where(status: params[:status]) if params[:status].present?
          scope = scope.search_task(params[:q]) if params[:q].present?
          page = paginate(scope)
          render json: { data: page[:records].map { |run| serialize_run(run) }, meta: page[:meta] }
        end

        def create
          task = ::Initiatives::Task.find(params[:task_id])
          run = ::Initiatives::Run.enqueue(task)
          run.persisted? ? render(json: serialize_run(run), status: :created) : render_errors(run)
        end

        def cancel
          run = ::Initiatives::Run.find(params[:id])
          return render(json: serialize_run(run)) if run.cancel!

          run.errors.add(:base, "A execução já terminou")
          render_errors(run)
        end

        private

        def render_history
          task = ::Initiatives::Task.find(params[:task_id])
          render json: task.runs.includes(*INCLUDES).order(id: :desc).map { |run| serialize_run(run) }
        end
      end
    end
  end
end
