module Api
  module V1
    module Codes
      class SnippetsController < ApplicationController
        before_action :set_snippet, only: %i[show update destroy]

        # Mesmo abaixo de 1 MB, um texto com muitas palavras diferentes estoura o índice de busca.
        rescue_from ActiveRecord::StatementInvalid do |error|
          raise error unless error.cause.is_a?(PG::ProgramLimitExceeded)

          render json: { errors: [ "Conteúdo grande demais para ser pesquisável" ],
                         fields: { content: [ "é grande demais para ser pesquisável" ] } },
                 status: :unprocessable_entity
        end

        # GET /api/v1/codes/snippets?q=termo&language=ruby&tag=rails&page=1
        def index
          scope = ::Codes::Snippet.order(updated_at: :desc)
          scope = scope.search(params[:q]) if params[:q].present?
          scope = scope.in_language(params[:language]) if params[:language].present?
          scope = scope.with_tag(params[:tag]) if params[:tag].present?

          page = paginate(scope)
          render json: { data: page[:records].map { |s| serialize_summary(s) }, meta: page[:meta] }
        end

        def show
          render json: serialize(@snippet)
        end

        def create
          snippet = ::Codes::Snippet.new(snippet_params)
          snippet.save ? render(json: serialize(snippet), status: :created) : render_errors(snippet)
        end

        def update
          @snippet.update(snippet_params) ? render(json: serialize(@snippet)) : render_errors(@snippet)
        end

        def destroy
          @snippet.destroy
          head :no_content
        end

        private

        def set_snippet
          @snippet = ::Codes::Snippet.find(params[:id])
        end

        def snippet_params
          params.require(:snippet).permit(:title, :description, :language, :content, :tags, tags: [])
        end

        # A listagem não traz o conteúdo: cada nota pode ter até 1 MB.
        def serialize_summary(snippet)
          snippet.as_json(only: %i[id title language tags created_at updated_at])
            .merge(display_title: snippet.display_title)
        end

        def serialize(snippet)
          serialize_summary(snippet).merge(snippet.as_json(only: %i[content description]))
        end
      end
    end
  end
end
