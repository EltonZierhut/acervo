module Api
  module V1
    module Codes
      class ProjectsController < ApplicationController
        before_action :set_project, only: %i[show update destroy]

        # GET /api/v1/codes/projects?q=termo
        def index
          scope = ::Codes::Project.left_joins(:snippets)
            .select("codes_projects.*, COUNT(codes_snippets.id) AS snippets_count")
            .group("codes_projects.id")
            .order(:name)
          scope = scope.search(params[:q]) if params[:q].present?

          render json: scope.map { |project| serialize(project, snippets_count: project.snippets_count) }
        end

        def show
          render json: serialize(@project).merge(
            snippets: @project.snippets.order(updated_at: :desc).map { |s| SnippetsController.serialize(s) }
          )
        end

        def create
          project = ::Codes::Project.new(project_params)
          project.save ? render(json: serialize(project), status: :created) : render_errors(project)
        end

        def update
          @project.update(project_params) ? render(json: serialize(@project)) : render_errors(@project)
        end

        def destroy
          @project.destroy
          head :no_content
        end

        private

        def set_project
          @project = ::Codes::Project.find(params[:id])
        end

        def project_params
          params.require(:project).permit(:name, :description, :repository_url, :tags, tags: [])
        end

        def serialize(project, extra = {})
          project.as_json(only: %i[id name description repository_url tags created_at updated_at]).merge(extra)
        end
      end
    end
  end
end
