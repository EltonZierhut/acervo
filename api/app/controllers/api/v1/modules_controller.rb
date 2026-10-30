# Lista os módulos habilitados. O frontend usa isto para montar o menu.
module Api
  module V1
    class ModulesController < ApplicationController
      def index
        modules = Rails.application.config.x.acervo_modules.select { |m| m[:enabled] }
        render json: modules.map { |m| m.slice(:key, :name, :description) }
      end
    end
  end
end
