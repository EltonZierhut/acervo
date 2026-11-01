module Api
  module V1
    module Initiatives
      module Executor
        class RunsController < BaseController
          before_action :set_run

          rescue_from ::Initiatives::Run::InvalidTransition do
            render json: { error: "A execução não está em andamento" }, status: :conflict
          end

          def heartbeat
            render json: { cancel: @run.heartbeat! }
          end

          def questions
            bodies = Array(params[:questions]).map { |body| body.to_s.strip }.reject(&:blank?)
            raise ArgumentError, "Informe ao menos uma pergunta" if bodies.empty?

            @run.ask!(bodies)
            head :ok
          end

          def complete
            @run.complete!(
              status: params[:status].to_s,
              **params.permit(:summary, :branch, :pull_request_url, :failure_kind, :failure_reason).to_h.symbolize_keys
            )
            head :ok
          end

          private

          def set_run
            @run = ::Initiatives::Run.find(params[:id])
          end
        end
      end
    end
  end
end
