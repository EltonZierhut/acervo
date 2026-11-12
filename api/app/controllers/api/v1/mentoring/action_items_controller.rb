module Api
  module V1
    module Mentoring
      class ActionItemsController < ApplicationController
        include Serialization

        before_action :set_action_item, only: %i[update destroy]

        # GET /api/v1/mentoring/mentorships/:mentorship_id/action_items?meeting_id=1&status=open|done
        def index
          scope = find_mentorship.action_items.includes(:goal, :meeting).ordered
          scope = scope.where(meeting_id: params[:meeting_id]) if params[:meeting_id].present?
          scope = scope.pending if params[:status] == "open"
          scope = scope.completed if params[:status] == "done"
          render json: { data: scope.map { |item| serialize_action_item(item) } }
        end

        def create
          item = find_mentorship.action_items.new(action_item_params)
          item.save ? render(json: serialize_action_item(item), status: :created) : render_errors(item)
        end

        def update
          @action_item.update(action_item_params) ? render(json: serialize_action_item(@action_item)) : render_errors(@action_item)
        end

        def destroy
          @action_item.destroy
          head :no_content
        end

        private

        def set_action_item
          @action_item = ::Mentoring::ActionItem.find(params[:id])
        end

        def action_item_params
          params.require(:action_item).permit(:title, :due_on, :meeting_id, :goal_id, :done)
        end
      end
    end
  end
end
