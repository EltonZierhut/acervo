module Api
  module V1
    module Mentoring
      class GoalsController < ApplicationController
        include Serialization

        before_action :set_goal, only: %i[update destroy]

        def index
          goals = find_mentorship.goals.ordered.to_a
          progress = action_progress(:goal_id, goals.map(&:id))
          render json: { data: goals.map { |goal| serialize_goal(goal, progress.fetch(goal.id)) } }
        end

        def create
          goal = find_mentorship.goals.new(goal_params)
          goal.save ? render(json: serialize_goal(goal), status: :created) : render_errors(goal)
        end

        def update
          @goal.update(goal_params) ? render(json: serialize_goal(@goal)) : render_errors(@goal)
        end

        def destroy
          @goal.destroy
          head :no_content
        end

        private

        def set_goal
          @goal = ::Mentoring::Goal.find(params[:id])
        end

        def goal_params
          params.require(:goal).permit(:title, :success_criteria, :description, :target_on, :status, :progress)
        end
      end
    end
  end
end
