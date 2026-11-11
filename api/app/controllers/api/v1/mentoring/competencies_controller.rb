module Api
  module V1
    module Mentoring
      class CompetenciesController < ApplicationController
        include Serialization

        before_action :set_competency, only: %i[update destroy]

        def index
          render json: { data: find_mentorship.competencies.map { |c| serialize_competency(c) } }
        end

        def create
          competency = find_mentorship.competencies.new(competency_params)
          competency.save ? render(json: serialize_competency(competency), status: :created) : render_errors(competency)
        end

        def update
          @competency.update(competency_params) ? render(json: serialize_competency(@competency)) : render_errors(@competency)
        end

        # Apaga também as notas da competência (cascata no banco).
        def destroy
          @competency.destroy
          head :no_content
        end

        private

        def set_competency
          @competency = ::Mentoring::Competency.find(params[:id])
        end

        def competency_params
          params.require(:competency).permit(:name)
        end
      end
    end
  end
end
