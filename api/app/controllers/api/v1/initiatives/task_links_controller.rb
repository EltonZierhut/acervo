module Api
  module V1
    module Initiatives
      class TaskLinksController < ApplicationController
        before_action :set_task, only: %i[index create]
        before_action :set_link, only: %i[update destroy]

        def index
          render json: @task.links.ordered.map { |link| serialize(link) }
        end

        def create
          link = @task.links.new(link_params)
          link.save ? render(json: serialize(link), status: :created) : render_errors(link)
        end

        def update
          @link.update(link_params) ? render(json: serialize(@link)) : render_errors(@link)
        end

        def destroy
          @link.destroy
          head :no_content
        end

        private

        def set_task
          @task = ::Initiatives::Task.find(params[:task_id])
        end

        def set_link
          @link = ::Initiatives::TaskLink.find(params[:id])
        end

        def link_params
          params.require(:task_link).permit(:url, :title)
        end

        def serialize(link)
          link.as_json(only: %i[id url title])
        end
      end
    end
  end
end
