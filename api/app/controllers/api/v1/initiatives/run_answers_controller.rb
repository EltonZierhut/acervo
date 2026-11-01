module Api
  module V1
    module Initiatives
      class RunAnswersController < ApplicationController
        include RunSerialization

        # POST .../runs/:run_id/answers { answers: [{ question_id:, answer: }] }
        def create
          run = ::Initiatives::Run.find(params[:run_id])
          answers = params.fetch(:answers, []).map { |item| [ item[:question_id], item[:answer] ] }
          return reject(run, "Escreva a resposta") if answers.empty?

          run.answer!(answers)
          render json: serialize_run(run.reload)
        rescue ::Initiatives::Run::InvalidTransition
          reject(run, "A execução não está aguardando resposta")
        rescue ArgumentError, ActiveRecord::RecordInvalid => e
          reject(run, e.message)
        end

        private

        def reject(run, message)
          run.errors.add(:base, message)
          render_errors(run)
        end
      end
    end
  end
end
