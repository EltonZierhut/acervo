module Api
  module V1
    module Initiatives
      class MilestonesController < ApplicationController
        before_action :set_initiative, only: %i[index create]
        before_action :set_milestone, only: %i[update destroy]

        # GET /api/v1/initiatives/initiatives/:initiative_id/milestones
        def index
          milestones = @initiative.milestones.ordered.to_a
          progress = ::Initiatives::Milestone.progress_for(milestones.map(&:id))
          render json: { data: milestones.map { |m| serialize(m, progress[m.id]) } }
        end

        def create
          milestone = @initiative.milestones.new(milestone_params)
          milestone.save ? render(json: serialize(milestone), status: :created) : render_errors(milestone)
        end

        def update
          @milestone.update(milestone_params) ? render(json: serialize(@milestone)) : render_errors(@milestone)
        end

        # As tarefas ligadas ficam sem marco (ON DELETE SET NULL).
        def destroy
          @milestone.destroy
          head :no_content
        end

        private

        def set_initiative
          @initiative = ::Initiatives::Initiative.find(params[:initiative_id])
        end

        def set_milestone
          @milestone = ::Initiatives::Milestone.find(params[:id])
        end

        def milestone_params
          params.require(:milestone).permit(:title, :description, :due_on, :completed)
        end

        def serialize(milestone, progress = :load)
          progress = ::Initiatives::Milestone.progress_for([ milestone.id ])[milestone.id] if progress == :load
          milestone.as_json(only: %i[id initiative_id title description due_on completed_at created_at updated_at])
            .merge(progress: progress || { done: 0, total: 0 })
        end
      end
    end
  end
end
