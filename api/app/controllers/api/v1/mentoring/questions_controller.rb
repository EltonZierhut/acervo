module Api
  module V1
    module Mentoring
      class QuestionsController < ApplicationController
        include Serialization

        before_action :set_question, only: %i[update destroy move]

        def index
          render json: { data: find_mentorship.questions.map { |q| serialize_question(q) } }
        end

        def create
          question = find_mentorship.questions.new(question_params)
          question.save ? render(json: serialize_question(question), status: :created) : render_errors(question)
        end

        def update
          @question.update(question_params) ? render(json: serialize_question(@question)) : render_errors(@question)
        end

        def destroy
          @question.destroy
          head :no_content
        end

        # POST /api/v1/mentoring/questions/:id/move { direction: "up" | "down" } — devolve a lista reordenada.
        def move
          unless %w[up down].include?(params[:direction])
            return render json: { error: "Direção precisa ser up ou down" }, status: :bad_request
          end

          @question.move!(params[:direction])
          render json: { data: @question.mentorship.questions.reload.map { |q| serialize_question(q) } }
        end

        private

        def set_question
          @question = ::Mentoring::Question.find(params[:id])
        end

        def question_params
          params.require(:question).permit(:prompt, :answer)
        end
      end
    end
  end
end
