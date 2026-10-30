module Api
  module V1
    module Codes
      class SnippetsController < ApplicationController
        before_action :set_snippet, only: %i[show update destroy]

        def self.serialize(snippet)
          snippet.as_json(only: %i[id title description language content tags project_id created_at updated_at])
            .merge(project: snippet.project&.slice(:id, :name))
        end

        # GET /api/v1/codes/snippets?q=termo&language=ruby&tag=rails&project_id=1&page=1
        def index
          scope = ::Codes::Snippet.includes(:project).order(updated_at: :desc)
          scope = scope.search(params[:q]) if params[:q].present?
          scope = scope.in_language(params[:language]) if params[:language].present?
          scope = scope.with_tag(params[:tag]) if params[:tag].present?
          scope = scope.where(project_id: params[:project_id]) if params[:project_id].present?

          page = paginate(scope)
          render json: { data: page[:records].map { |s| self.class.serialize(s) }, meta: page[:meta] }
        end

        def show
          render json: self.class.serialize(@snippet)
        end

        def create
          snippet = ::Codes::Snippet.new(snippet_params)
          snippet.save ? render(json: self.class.serialize(snippet), status: :created) : render_errors(snippet)
        end

        def update
          @snippet.update(snippet_params) ? render(json: self.class.serialize(@snippet)) : render_errors(@snippet)
        end

        def destroy
          @snippet.destroy
          head :no_content
        end

        private

        def set_snippet
          @snippet = ::Codes::Snippet.includes(:project).find(params[:id])
        end

        def snippet_params
          params.require(:snippet).permit(:title, :description, :language, :content, :project_id, :tags, tags: [])
        end
      end
    end
  end
end
