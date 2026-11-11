module Api
  module V1
    module Mentoring
      class MentorshipsController < ApplicationController
        include Serialization

        before_action :set_mentorship, only: %i[show update destroy overview]

        # GET /api/v1/mentoring/mentorships — todas, ativas primeiro, com um resumo de cada.
        def index
          render json: { data: serialize_mentorships(::Mentoring::Mentorship.listed) }
        end

        def show
          render json: serialize_mentorship(@mentorship)
        end

        # As perguntas sugeridas entram por padrão; use_suggested_questions: false começa vazio.
        def create
          mentorship = ::Mentoring::Mentorship.new(mentorship_params)
          saved = ::Mentoring::Mentorship.transaction do
            next false unless mentorship.save

            suggested = ActiveModel::Type::Boolean.new.cast(params.fetch(:use_suggested_questions, true))
            mentorship.add_suggested_questions! if suggested
            true
          end
          saved ? render(json: serialize_mentorship(mentorship), status: :created) : render_errors(mentorship)
        end

        def update
          @mentorship.update(mentorship_params) ? render(json: serialize_mentorship(@mentorship)) : render_errors(@mentorship)
        end

        def destroy
          @mentorship.destroy
          head :no_content
        end

        # GET /api/v1/mentoring/mentorships/:id/overview — indicadores do painel.
        def overview
          data = ::Mentoring::Overview.new(@mentorship).to_h
          data[:action_items][:next] = data[:action_items][:next].map { |item| serialize_action_item(item) }
          render json: data
        end

        private

        def set_mentorship
          @mentorship = ::Mentoring::Mentorship.find(params[:id])
        end

        def mentorship_params
          params.require(:mentorship).permit(:mentor_name, :topic, :description, :started_on, :ended_on, :cadence, :status)
        end
      end
    end
  end
end
