module Api
  module V1
    module Mentoring
      # Autoavaliações: o conjunto de notas das competências numa data.
      class AssessmentsController < ApplicationController
        include Serialization

        before_action { @assessments = ::Mentoring::Assessments.new(find_mentorship) }

        def show
          render json: @assessments.to_h
        end

        # POST { rated_on: "2026-11-11", ratings: [{ competency_id:, score: 1..5 | null, comment: }] }
        def create
          entries = Array(params.require(:ratings)).map do |entry|
            entry.permit(:competency_id, :score, :comment).to_h.symbolize_keys
          end
          @assessments.save!(rated_on: params.require(:rated_on), entries:)
          render json: @assessments.to_h
        rescue ::Mentoring::Assessments::Invalid => e
          render json: { errors: e.errors, fields: {} }, status: :unprocessable_entity
        end

        def destroy
          @assessments.destroy_date!(params[:rated_on])
          head :no_content
        rescue ::Mentoring::Assessments::Invalid => e
          render json: { errors: e.errors, fields: {} }, status: :unprocessable_entity
        end
      end
    end
  end
end
