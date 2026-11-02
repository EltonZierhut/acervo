module Api
  module V1
    module Initiatives
      class TasksController < ApplicationController
        # O quadro mostra todas as colunas de uma vez, então a lista vem inteira, com um teto de segurança.
        LIMIT = 1_000

        before_action :set_initiative, only: %i[index create]
        before_action :set_task, only: %i[update destroy move]

        # GET /api/v1/initiatives/initiatives/:initiative_id/tasks?q=termo&status=todo&priority=high&number=12&milestone_id=1|none
        def index
          scope = @initiative.tasks.ordered
          scope = scope.where(status: params[:status]) if params[:status].present?
          scope = scope.where(priority: params[:priority]) if params[:priority].present?
          scope = scope.where(number: params[:number].to_i) if params[:number].present?
          scope = scope.in_milestone(params[:milestone_id]) if params[:milestone_id].present?
          scope = scope.search(params[:q]).reorder(nil).ordered if params[:q].present?

          total = scope.unscope(:order).count
          tasks = scope.limit(LIMIT).to_a
          extras = extras_for(tasks.map(&:id))
          render json: { data: tasks.map { |t| serialize(t, extras) },
                         meta: { total:, truncated: total > LIMIT } }
        end

        def create
          task = @initiative.tasks.new(task_params)
          task.save ? render(json: serialize(task), status: :created) : render_errors(task)
        end

        def update
          @task.update(task_params) ? render(json: serialize(@task)) : render_errors(@task)
        end

        # PATCH /api/v1/initiatives/tasks/:id/move { status:, position:, before_id: }
        # Muda a coluna e a posição de uma vez; a ordem fica salva.
        def move
          status = params[:status].to_s
          unless ::Initiatives::Task::STATUSES.value?(status)
            return render json: { errors: [ "Status inválido" ], fields: { status: [ "é inválido" ] } },
                          status: :unprocessable_entity
          end

          @task.move_to(status, index: params[:position].presence&.to_i, before_id: params[:before_id].presence)
          render json: serialize(@task)
        end

        def destroy
          @task.destroy
          head :no_content
        end

        private

        def set_initiative
          @initiative = ::Initiatives::Initiative.find(params[:initiative_id])
        end

        def set_task
          @task = ::Initiatives::Task.find(params[:id])
        end

        def task_params
          params.require(:task).permit(:title, :description, :status, :priority, :due_on, :milestone_id)
        end

        # Contagens e última execução numa consulta só para a lista inteira.
        def extras_for(ids)
          { images: ::Initiatives::TaskImage.where(task_id: ids).group(:task_id).count,
            links: ::Initiatives::TaskLink.where(task_id: ids).group(:task_id).count,
            runs: ::Initiatives::Run.latest_by_task(ids) }
        end

        def serialize(task, extras = extras_for([ task.id ]))
          run = extras[:runs][task.id]
          task.as_json(only: %i[id initiative_id milestone_id number position title description status priority due_on
                                completed_at created_at updated_at]).merge(
            images_count: extras[:images].fetch(task.id, 0),
            links_count: extras[:links].fetch(task.id, 0),
            latest_run: run&.as_json(only: %i[id status pull_request_url])
          )
        end
      end
    end
  end
end
