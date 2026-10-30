# Busca geral do módulo: procura em projetos e códigos ao mesmo tempo.
# GET /api/v1/codes/search?q=termo
module Api
  module V1
    module Codes
      class SearchController < ApplicationController
        def index
          term = params[:q].to_s.strip
          return render(json: { projects: [], snippets: [] }) if term.blank?

          projects = ::Codes::Project.search(term).limit(10)
          snippets = ::Codes::Snippet.includes(:project).search(term).limit(30)

          render json: {
            projects: projects.as_json(only: %i[id name description tags]),
            snippets: snippets.map { |s| SnippetsController.serialize(s) }
          }
        end
      end
    end
  end
end
