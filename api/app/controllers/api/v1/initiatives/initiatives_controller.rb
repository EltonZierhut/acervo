module Api
  module V1
    module Initiatives
      class InitiativesController < ApplicationController
        before_action :set_initiative, only: %i[show update destroy]

        # GET /api/v1/initiatives/initiatives?q=termo&status=active|all&context_id=1|none&page=1
        # Sem "status", as encerradas ficam de fora.
        def index
          scope = ::Initiatives::Initiative.includes(:context).ordered
          scope = filter_status(scope)
          scope = scope.in_context(params[:context_id]) if params[:context_id].present?
          scope = scope.search(params[:q]) if params[:q].present?

          page = paginate(scope)
          records = page[:records].to_a
          progress = ::Initiatives::Initiative.progress_for(records.map(&:id))
          render json: { data: records.map { |i| serialize_summary(i, progress[i.id]) }, meta: page[:meta] }
        end

        def show
          render json: serialize(@initiative)
        end

        def create
          initiative = ::Initiatives::Initiative.new(initiative_params)
          initiative.save ? render(json: serialize(initiative), status: :created) : render_errors(initiative)
        end

        def update
          @initiative.update(initiative_params) ? render(json: serialize(@initiative)) : render_errors(@initiative)
        end

        # Marcos e tarefas saem junto (ON DELETE CASCADE).
        def destroy
          @initiative.destroy
          head :no_content
        end

        private

        def set_initiative
          @initiative = ::Initiatives::Initiative.find(params[:id])
        end

        def filter_status(scope)
          case params[:status]
          when "all" then scope
          when nil, "" then scope.not_done
          else scope.where(status: params[:status])
          end
        end

        def initiative_params
          params.require(:initiative).permit(
            :name, :description, :context_id, :status, :priority, :starts_on, :due_on, :tags,
            tags: [], sections: []
          )
        end

        def serialize_summary(initiative, progress)
          initiative.as_json(only: %i[id name status priority starts_on due_on tags created_at updated_at]).merge(
            context: initiative.context&.as_json(only: %i[id name color]),
            progress: progress || { done: 0, total: 0 }
          )
        end

        def serialize(initiative)
          progress = ::Initiatives::Initiative.progress_for([ initiative.id ])[initiative.id]
          serialize_summary(initiative, progress).merge(initiative.as_json(only: %i[description sections]))
        end
      end
    end
  end
end
